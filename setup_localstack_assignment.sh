#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="http://localhost:4566"
REGION="us-east-1"
BUCKET="demo-upload-bucket"
ROLE_NAME="lambda-basic-role"
EVENT_FUNCTION="event-processor"
RESULT_FUNCTION="result-processor"
WORKDIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$WORKDIR/build"
mkdir -p "$BUILD_DIR"

cat > /tmp/lambda-role.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON

cat > /tmp/s3-notification.json <<JSON
{
  "LambdaFunctionConfigurations": [
    {
      "LambdaFunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:event-processor",
      "Events": ["s3:ObjectCreated:*"]
    }
  ]
}
JSON

python - <<'PY'
import os, zipfile
base = os.environ['WORKDIR'] if 'WORKDIR' in os.environ else os.getcwd()
# Use explicit paths for the repo workspace when run via bash.
if not os.path.exists(os.path.join(base, 'build')):
    os.makedirs(os.path.join(base, 'build'), exist_ok=True)
for name in ['event_processor.py', 'result_processor.py']:
    src = os.path.join(base, 'lambdas', name)
    dst = os.path.join(base, 'build', name)
    with open(src, 'rb') as fsrc, open(dst, 'wb') as fdst:
        fdst.write(fsrc.read())
    with zipfile.ZipFile(os.path.join(base, 'build', name.replace('.py', '.zip')), 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.write(dst, arcname=name)
PY

aws --endpoint-url="$ENDPOINT" --region "$REGION" s3api create-bucket --bucket "$BUCKET" >/dev/null 2>&1 || true
aws --endpoint-url="$ENDPOINT" --region "$REGION" iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file:///tmp/lambda-role.json >/dev/null 2>&1 || true

aws --endpoint-url="$ENDPOINT" --region "$REGION" lambda create-function \
  --function-name "$EVENT_FUNCTION" \
  --runtime python3.12 \
  --role arn:aws:iam::000000000000:role/$ROLE_NAME \
  --handler event_processor.lambda_handler \
  --zip-file fileb://$BUILD_DIR/event_processor.zip \
  --environment "Variables={AWS_ENDPOINT_URL=http://localhost:4566,RESULT_FUNCTION_NAME=$RESULT_FUNCTION}" \
  --timeout 30 --memory-size 128 >/dev/null 2>&1 || \
aws --endpoint-url="$ENDPOINT" --region "$REGION" lambda update-function-code \
  --function-name "$EVENT_FUNCTION" \
  --zip-file fileb://$BUILD_DIR/event_processor.zip >/dev/null

aws --endpoint-url="$ENDPOINT" --region "$REGION" lambda create-function \
  --function-name "$RESULT_FUNCTION" \
  --runtime python3.12 \
  --role arn:aws:iam::000000000000:role/$ROLE_NAME \
  --handler result_processor.lambda_handler \
  --zip-file fileb://$BUILD_DIR/result_processor.zip \
  --timeout 30 --memory-size 128 >/dev/null 2>&1 || \
aws --endpoint-url="$ENDPOINT" --region "$REGION" lambda update-function-code \
  --function-name "$RESULT_FUNCTION" \
  --zip-file fileb://$BUILD_DIR/result_processor.zip >/dev/null

aws --endpoint-url="$ENDPOINT" --region "$REGION" lambda add-permission \
  --function-name "$EVENT_FUNCTION" \
  --statement-id s3-trigger \
  --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn "arn:aws:s3:::$BUCKET" >/dev/null 2>&1 || true

aws --endpoint-url="$ENDPOINT" --region "$REGION" s3api put-bucket-notification-configuration \
  --bucket "$BUCKET" \
  --notification-configuration file:///tmp/s3-notification.json

aws --endpoint-url="$ENDPOINT" --region "$REGION" lambda list-functions
aws --endpoint-url="$ENDPOINT" --region "$REGION" s3 ls
