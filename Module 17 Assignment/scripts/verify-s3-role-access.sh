#!/bin/bash
set -euo pipefail

echo "Checking AWS identity..."
aws sts get-caller-identity

echo "Listing S3 buckets..."
aws s3 ls

echo "Creating a temporary test file..."
printf 'EC2 role access test on %s\n' "$(date -u)" > /tmp/ec2-role-test.txt

echo "Uploading test file to S3..."
aws s3 cp /tmp/ec2-role-test.txt s3://module17-demo-bucket/ec2-role-test.txt

echo "Downloading the file back..."
aws s3 cp s3://module17-demo-bucket/ec2-role-test.txt /tmp/ec2-role-test-downloaded.txt

cat /tmp/ec2-role-test-downloaded.txt

echo "S3 access verification complete."
