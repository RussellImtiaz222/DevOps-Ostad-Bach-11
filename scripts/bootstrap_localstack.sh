#!/usr/bin/env bash
set -euo pipefail

AWS_ENDPOINT="http://localhost:4566"
AWS_REGION="us-east-1"
BUCKET_NAME="demo-upload-bucket"
RESULT_FUNCTION_NAME="result-processor"
EVENT_FUNCTION_NAME="event-processor"

# Wait for LocalStack to be ready
for i in {1..30}; do
  if curl -sf "$AWS_ENDPOINT/_localstack/health" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

# Create bucket if needed
aws --endpoint-url="$AWS_ENDPOINT" s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null 2>&1 || \
aws --endpoint-url="$AWS_ENDPOINT" s3 mb s3://"$BUCKET_NAME" --region "$AWS_REGION"

# Ensure lambda role exists
aws --endpoint-url="$AWS_ENDPOINT" iam get-role --role-name lambda-basic-role >/dev/null 2>&1 || \
aws --endpoint-url="$AWS_ENDPOINT" iam create-role --role-name lambda-basic-role --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

# Package Lambda code
mkdir -p /tmp/lambda-builds
cp lambdas/event_processor.py /tmp/lambda-builds/event_processor.py
cp lambdas/result_processor.py /tmp/lambda-builds/result_processor.py

# Create function zip files
cd /tmp/lambda-builds
zip -j event_processor.zip event_processor.py
zip -j result_processor.zip result_processor.py

# Create/Update event processor
aws --endpoint-url="$AWS_ENDPOINT" lambda get-function --function-name "$EVENT_FUNCTION_NAME" >/dev/null 2>&1 || \
aws --endpoint-url="$AWS_ENDPOINT" lambda create-function \
  --function-name "$EVENT_FUNCTION_NAME" \
  --runtime python3.12 \
  --role arn:aws:iam::000000000000:role/lambda-basic-role \
  --handler event_processor.lambda_handler \
  --zip-file fileb://event_processor.zip \
  --environment Variables={AWS_ENDPOINT_URL=http://localhost:4566,RESULT_FUNCTION_NAME=$RESULT_FUNCTION_NAME} \
  --region "$AWS_REGION"

# Create/Update result processor
aws --endpoint-url="$AWS_ENDPOINT" lambda get-function --function-name "$RESULT_FUNCTION_NAME" >/dev/null 2>&1 || \
aws --endpoint-url="$AWS_ENDPOINT" lambda create-function \
  --function-name "$RESULT_FUNCTION_NAME" \
  --runtime python3.12 \
  --role arn:aws:iam::000000000000:role/lambda-basic-role \
  --handler result_processor.lambda_handler \
  --zip-file fileb://result_processor.zip \
  --region "$AWS_REGION"

# Ensure function invocation policy allows S3 to invoke lambda
aws --endpoint-url="$AWS_ENDPOINT" s3api put-bucket-notification-configuration \
  --bucket "$BUCKET_NAME" \
  --notification-configuration '{"LambdaFunctionConfigurations":[{"LambdaFunctionArn":"arn:aws:lambda:us-east-1:000000000000:function:event-processor","Events":["s3:ObjectCreated:*"]}]}'

# Print summary
echo "LocalStack bootstrap complete. Bucket: $BUCKET_NAME"
echo "Event function: $EVENT_FUNCTION_NAME"
echo "Result function: $RESULT_FUNCTION_NAME"
