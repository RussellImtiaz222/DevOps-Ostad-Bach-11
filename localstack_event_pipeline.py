import json
import os
import zipfile
from io import BytesIO
from pathlib import Path

import boto3

ENDPOINT = "http://localhost:4566"
REGION = "us-east-1"
BUCKET_NAME = "demo-upload-bucket"
EVENT_FUNCTION_NAME = "event-processor"
RESULT_FUNCTION_NAME = "result-processor"
ROLE_NAME = "lambda-basic-role"
ROLE_ARN = f"arn:aws:iam::000000000000:role/{ROLE_NAME}"

BASE_DIR = Path(__file__).resolve().parent
LAMBDA_DIR = BASE_DIR / "lambdas"
BUILD_DIR = BASE_DIR / "build"
BUILD_DIR.mkdir(exist_ok=True)


def make_client(service_name: str):
    return boto3.client(
        service_name,
        region_name=REGION,
        endpoint_url=ENDPOINT,
        aws_access_key_id="test",
        aws_secret_access_key="test",
        aws_session_token="test",
    )


def create_role():
    client = make_client("iam")
    try:
        return client.get_role(RoleName=ROLE_NAME)["Role"]["Arn"]
    except client.exceptions.NoSuchEntityException:
        policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"Service": "lambda.amazonaws.com"},
                    "Action": "sts:AssumeRole",
                }
            ],
        }
        return client.create_role(
            RoleName=ROLE_NAME,
            AssumeRolePolicyDocument=json.dumps(policy),
        )["Role"]["Arn"]


def zip_lambda_code(function_name: str):
    source_name = function_name.replace("-", "_")
    source_file = LAMBDA_DIR / f"{source_name}.py"
    if not source_file.exists():
        raise FileNotFoundError(f"Lambda source file not found: {source_file}")
    zip_buffer = BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(source_file, arcname=source_file.name)
    return zip_buffer.getvalue()


def ensure_bucket():
    s3 = make_client("s3")
    try:
        s3.head_bucket(Bucket=BUCKET_NAME)
    except Exception:
        s3.create_bucket(Bucket=BUCKET_NAME)
    return "ok"


def ensure_lambda(function_name: str, handler: str, env_vars: dict | None = None):
    client = make_client("lambda")
    zip_bytes = zip_lambda_code(function_name)
    payload = {
        "FunctionName": function_name,
        "Runtime": "python3.12",
        "Role": ROLE_ARN,
        "Handler": handler,
        "Code": {"ZipFile": zip_bytes},
        "Timeout": 30,
        "MemorySize": 128,
    }
    if env_vars:
        payload["Environment"] = {"Variables": env_vars}
    try:
        client.get_function(FunctionName=function_name)
        client.update_function_code(FunctionName=function_name, ZipFile=zip_bytes)
        if env_vars:
            client.update_function_configuration(
                FunctionName=function_name,
                Environment={"Variables": env_vars},
                Timeout=30,
                MemorySize=128,
            )
        return {"status": "updated", "function": function_name}
    except client.exceptions.ResourceNotFoundException:
        client.create_function(**payload)
        return {"status": "created", "function": function_name}


def configure_s3_trigger():
    lambda_client = make_client("lambda")
    try:
        lambda_client.get_policy(FunctionName=EVENT_FUNCTION_NAME)
    except Exception:
        lambda_client.add_permission(
            FunctionName=EVENT_FUNCTION_NAME,
            StatementId="s3-trigger-1",
            Action="lambda:InvokeFunction",
            Principal="s3.amazonaws.com",
            SourceArn=f"arn:aws:s3:::{BUCKET_NAME}",
        )

    s3_client = make_client("s3")
    notification = {
        "LambdaFunctionConfigurations": [
            {
                "LambdaFunctionArn": f"arn:aws:lambda:{REGION}:000000000000:function:{EVENT_FUNCTION_NAME}",
                "Events": ["s3:ObjectCreated:*"],
            }
        ]
    }
    s3_client.put_bucket_notification_configuration(
        Bucket=BUCKET_NAME,
        NotificationConfiguration=notification,
    )
    return {"status": "configured", "notification": notification}


def upload_sample_file():
    local_file = BASE_DIR / "sample-data" / "demo.txt"
    s3 = make_client("s3")
    s3.put_object(Bucket=BUCKET_NAME, Key="demo/demo.txt", Body=local_file.read_bytes(), ContentType="text/plain")
    return {"bucket": BUCKET_NAME, "key": "demo/demo.txt", "size": local_file.stat().st_size}


def invoke_event_processor():
    lambda_client = make_client("lambda")
    payload = {
        "Records": [
            {
                "s3": {
                    "bucket": {"name": BUCKET_NAME},
                    "object": {"key": "demo/demo.txt", "size": 76},
                }
            }
        ]
    }
    response = lambda_client.invoke(
        FunctionName=EVENT_FUNCTION_NAME,
        InvocationType="RequestResponse",
        Payload=json.dumps(payload),
    )
    body = response["Payload"].read().decode("utf-8")
    try:
        parsed = json.loads(body)
    except json.JSONDecodeError:
        parsed = body
    return parsed


def invoke_result_function():
    payload = {
        "file_name": "demo.txt",
        "file_extension": "txt",
        "bucket": BUCKET_NAME,
        "key": "demo/demo.txt",
        "custom_message": "Manual test of result processor",
    }
    response = make_client("lambda").invoke(
        FunctionName=RESULT_FUNCTION_NAME,
        InvocationType="RequestResponse",
        Payload=json.dumps(payload),
    )
    return json.loads(response["Payload"].read().decode("utf-8"))


def main():
    print("[1/6] Ensuring IAM role exists")
    print(create_role())
    print("[2/6] Ensuring S3 bucket exists")
    print(ensure_bucket())
    print("[3/6] Deploying event lambda")
    docker_endpoint = ENDPOINT.replace("localhost", "host.docker.internal")
    print(ensure_lambda(EVENT_FUNCTION_NAME, "event_processor.lambda_handler", {"AWS_ENDPOINT_URL": docker_endpoint, "RESULT_FUNCTION_NAME": RESULT_FUNCTION_NAME}))
    print("[4/6] Deploying result lambda")
    print(ensure_lambda(RESULT_FUNCTION_NAME, "result_processor.lambda_handler", {}))
    print("[5/6] Configuring S3 notification trigger")
    print(configure_s3_trigger())
    print("[6/6] Uploading sample object and invoking workflow")
    upload = upload_sample_file()
    print(upload)
    print("Event response:")
    print(json.dumps(invoke_event_processor(), indent=2, default=str))
    print("Result function response:")
    print(json.dumps(invoke_result_function(), indent=2, default=str))


if __name__ == "__main__":
    main()
