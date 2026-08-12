import boto3

endpoint='http://localhost:4566'
region='us-east-1'

c=boto3.client('lambda', endpoint_url=endpoint, region_name=region, aws_access_key_id='test', aws_secret_access_key='test', aws_session_token='test')
print('FUNCTIONS')
print(c.list_functions())

print('POLICY')
try:
    print(c.get_policy(FunctionName='event-processor'))
except Exception as e:
    print(type(e).__name__, e)

s3=boto3.client('s3', endpoint_url=endpoint, region_name=region, aws_access_key_id='test', aws_secret_access_key='test', aws_session_token='test')
print('NOTIF')
try:
    print(s3.get_bucket_notification_configuration(Bucket='demo-upload-bucket'))
except Exception as e:
    print(type(e).__name__, e)
