import json
import boto3

endpoint='http://localhost:4566'
region='us-east-1'

c=boto3.client('lambda', endpoint_url=endpoint, region_name=region, aws_access_key_id='test', aws_secret_access_key='test', aws_session_token='test')
print('list functions before')
print(c.list_functions())

print('adding permission...')
try:
    r = c.add_permission(
        FunctionName='event-processor',
        StatementId='s3-trigger',
        Action='lambda:InvokeFunction',
        Principal='s3.amazonaws.com',
        SourceArn='arn:aws:s3:::demo-upload-bucket'
    )
    print(r)
except Exception as e:
    print('permission error', type(e).__name__, e)

print('get policy...')
try:
    print(c.get_policy(FunctionName='event-processor'))
except Exception as e:
    print('get policy error', type(e).__name__, e)

s3=boto3.client('s3', endpoint_url=endpoint, region_name=region, aws_access_key_id='test', aws_secret_access_key='test', aws_session_token='test')
print('put notification...')
try:
    r = s3.put_bucket_notification_configuration(
        Bucket='demo-upload-bucket',
        NotificationConfiguration={
            'LambdaFunctionConfigurations': [
                {
                    'LambdaFunctionArn': 'arn:aws:lambda:us-east-1:000000000000:function:event-processor',
                    'Events': ['s3:ObjectCreated:*'],
                    'Filter': {'Key': {'FilterRules': []}}
                }
            ]
        }
    )
    print(r)
except Exception as e:
    print('notification error', type(e).__name__, e)

print('get notification...')
try:
    print(s3.get_bucket_notification_configuration(Bucket='demo-upload-bucket'))
except Exception as e:
    print('get notif error', type(e).__name__, e)
