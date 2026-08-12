import json
import os
from datetime import datetime

import boto3


def lambda_handler(event, context):
    records = event.get("Records", [])
    if not records:
        return {"status": "no_records", "message": "No S3 records found in event."}

    s3_record = records[0]["s3"]
    bucket_name = s3_record["bucket"]["name"]
    object_key = s3_record["object"]["key"]
    size_bytes = s3_record["object"].get("size", 0)

    endpoint_url = os.environ.get("AWS_ENDPOINT_URL", "http://host.docker.internal:4566")
    if endpoint_url.startswith("http://localhost:"):
        endpoint_url = endpoint_url.replace("http://localhost:", "http://host.docker.internal:")
    s3_client = boto3.client("s3", endpoint_url=endpoint_url, region_name="us-east-1")
    head = s3_client.head_object(Bucket=bucket_name, Key=object_key)

    processed = {
        "bucket": bucket_name,
        "key": object_key,
        "size_bytes": size_bytes,
        "file_name": object_key.split('/')[-1],
        "file_extension": object_key.split('.')[-1] if '.' in object_key else "",
        "upload_time": datetime.utcnow().isoformat() + "Z",
        "content_type": head.get("ContentType", "unknown"),
        "message": "File event received and processed successfully."
    }

    lambda_client = boto3.client("lambda", endpoint_url=endpoint_url, region_name="us-east-1")
    invoke_response = lambda_client.invoke(
        FunctionName=os.environ["RESULT_FUNCTION_NAME"],
        InvocationType="RequestResponse",
        Payload=json.dumps(processed)
    )
    payload = invoke_response["Payload"].read()

    body = json.loads(payload.decode("utf-8"))
    if isinstance(body, str):
        body = json.loads(body)

    response = {
        "status": "processed",
        "event": processed,
        "result_function_response": body,
        "message": "S3 upload event triggered Lambda processing and forwarded payload to Function 2."
    }
    return response
