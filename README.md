# Module 16 Assignment - LocalStack Event Pipeline

## 📋 Overview

This project demonstrates a complete serverless event processing pipeline using **LocalStack**, an emulator for AWS services. The pipeline implements a two-stage Lambda function architecture that processes S3 upload events in a local development environment.

**Key Features:**
- ✅ S3 bucket with event notifications
- ✅ Two-stage Lambda function pipeline
- ✅ Event-driven architecture
- ✅ Docker-based Lambda execution
- ✅ CloudWatch Logs integration
- ✅ IAM role configuration
- ✅ Complete end-to-end automation

---

## 🏗️ Architecture

### Components

```
S3 Event Upload
        ↓
    [demo-upload-bucket]
        ↓
   (s3:ObjectCreated:* trigger)
        ↓
[Lambda 1: event-processor]
   • Receives S3 event
   • Extracts file metadata
   • Invokes Lambda 2
        ↓
[Lambda 2: result-processor]
   • Processes metadata
   • Transforms filename to uppercase
   • Returns final response
        ↓
    Response Output
```

### Services

| Service | Status | Details |
|---------|--------|---------|
| **LocalStack** | Running | AWS service emulator (v3.8) |
| **Docker** | Running | Container runtime for Lambda execution |
| **S3** | Deployed | demo-upload-bucket (us-east-1) |
| **Lambda** | Deployed | 2 functions (event-processor, result-processor) |
| **IAM** | Deployed | lambda-basic-role with execution policy |
| **CloudWatch Logs** | Deployed | Logging for both Lambda functions |

---

## 📁 Project Structure

```
Module 16 Assignment/
├── README.md                          # This file
├── docker-compose.yml                 # LocalStack container orchestration
├── localstack_event_pipeline.py       # Main orchestration script
├── debug_s3_trigger.py                # S3 event debugging utility
├── diagnose_localstack.py             # LocalStack diagnostics
├── role.json                          # IAM trust policy definition
├── setup_localstack_assignment.sh     # Setup script (Bash)
│
├── lambdas/                           # Lambda function source code
│   ├── event_processor.py             # Stage 1: S3 event handler
│   └── result_processor.py            # Stage 2: Data processor
│
├── build/                             # Compiled/packaged code
│   ├── event_processor.py
│   └── result_processor.py
│
├── sample-data/                       # Test data
│   └── demo.txt                       # Sample file for testing
│
├── scripts/                           # Utility scripts
│   └── bootstrap_localstack.sh        # LocalStack bootstrap
│
└── localstack-data/                   # LocalStack persistent data
    └── (generated automatically)
```

---

## 🚀 Quick Start

### Prerequisites

- Python 3.12+
- Docker & Docker Compose
- boto3 (AWS SDK for Python)
- Windows/Linux/macOS with terminal access

### Installation

1. **Clone or navigate to the project directory:**
   ```bash
   cd "C:\Users\iruss\Module 16 Assignment"
   ```

2. **Create a Python virtual environment:**
   ```bash
   python -m venv .venv
   ```

3. **Activate the virtual environment:**
   - **Windows (PowerShell):**
     ```powershell
     .\.venv\Scripts\Activate.ps1
     ```
   - **Windows (CMD):**
     ```cmd
     .venv\Scripts\activate.bat
     ```
   - **Linux/macOS:**
     ```bash
     source .venv/bin/activate
     ```

4. **Install dependencies:**
   ```bash
   pip install boto3
   ```

### Running the Project

1. **Start LocalStack:**
   ```bash
   docker-compose up -d
   ```

2. **Verify LocalStack is healthy:**
   ```bash
   docker ps | grep localstack-lab
   ```
   Expected output: Container should show status "Up" and "(healthy)"

3. **Run the event pipeline:**
   ```bash
   python localstack_event_pipeline.py
   ```

   This will:
   - ✅ Create IAM role (lambda-basic-role)
   - ✅ Create S3 bucket (demo-upload-bucket)
   - ✅ Deploy event-processor Lambda
   - ✅ Deploy result-processor Lambda
   - ✅ Configure S3 event notifications
   - ✅ Upload sample file (demo.txt)
   - ✅ Execute complete event pipeline
   - ✅ Display responses from both Lambda functions

4. **Stop LocalStack (when done):**
   ```bash
   docker-compose down
   ```

---

## 📊 Deployed Resources

### S3 Bucket
- **Name:** `demo-upload-bucket`
- **Region:** `us-east-1`
- **Event Notification:** Configured to trigger `event-processor` Lambda on `s3:ObjectCreated:*`
- **Test File:** `demo/demo.txt` (82 bytes)

### Lambda Functions

#### Function 1: event-processor
- **Runtime:** Python 3.12
- **Handler:** `event_processor.lambda_handler`
- **Memory:** 128 MB
- **Timeout:** 30 seconds
- **Code Size:** 973 bytes
- **Environment Variables:**
  - `AWS_ENDPOINT_URL`: http://host.docker.internal:4566
  - `RESULT_FUNCTION_NAME`: result-processor
- **Functionality:**
  - Receives S3 event
  - Extracts file metadata (bucket, key, size, content-type)
  - Invokes result-processor Lambda
  - Returns processed response

#### Function 2: result-processor
- **Runtime:** Python 3.12
- **Handler:** `result_processor.lambda_handler`
- **Memory:** 128 MB
- **Timeout:** 30 seconds
- **Code Size:** 487 bytes
- **Functionality:**
  - Receives processed event data
  - Transforms filename to uppercase
  - Returns final response with metadata

### IAM Role
- **Name:** `lambda-basic-role`
- **ARN:** `arn:aws:iam::000000000000:role/lambda-basic-role`
- **Trust Policy:** Allows Lambda service to assume role
- **Permissions:** Basic Lambda execution policy

### CloudWatch Logs
- **Log Groups:**
  - `/aws/lambda/event-processor`
  - `/aws/lambda/result-processor`

---

## 🧪 Testing & Verification

### Manual Test - Upload File to S3

```python
import boto3

s3 = boto3.client('s3', endpoint_url='http://localhost:4566', 
                  region_name='us-east-1',
                  aws_access_key_id='test', 
                  aws_secret_access_key='test')

# Upload a test file
with open('sample-data/demo.txt', 'rb') as f:
    s3.put_object(Bucket='demo-upload-bucket', Key='test/myfile.txt', Body=f)
```

### Manual Lambda Invocation

```python
import boto3
import json

lam = boto3.client('lambda', endpoint_url='http://localhost:4566',
                   region_name='us-east-1',
                   aws_access_key_id='test',
                   aws_secret_access_key='test')

# Invoke event-processor with sample S3 event
event = {
    'Records': [{
        's3': {
            'bucket': {'name': 'demo-upload-bucket'},
            'object': {'key': 'demo/demo.txt'}
        }
    }]
}

response = lam.invoke(FunctionName='event-processor',
                     InvocationType='RequestResponse',
                     Payload=json.dumps(event))

print(json.loads(response['Payload'].read()))
```

### View Lambda Logs

```bash
# Using AWS CLI
aws logs tail /aws/lambda/event-processor --follow --endpoint-url http://localhost:4566

# Or in Python
import boto3

logs = boto3.client('logs', endpoint_url='http://localhost:4566',
                   region_name='us-east-1',
                   aws_access_key_id='test',
                   aws_secret_access_key='test')

response = logs.describe_log_streams(logGroupName='/aws/lambda/event-processor')
for stream in response['logStreams']:
    print(f"Log Stream: {stream['logStreamName']}")
```

---

## 📝 Example Output

### Event Processor Response
```json
{
  "status": "processed",
  "event": {
    "bucket": "demo-upload-bucket",
    "key": "demo/demo.txt",
    "size_bytes": 76,
    "file_name": "demo.txt",
    "file_extension": "txt",
    "upload_time": "2026-08-12T21:46:42.960418Z",
    "content_type": "text/plain"
  },
  "result_function_response": {
    "status": "ok",
    "message": "File 'demo.txt' was successfully processed",
    "file_name_upper": "DEMO.TXT",
    "file_extension": "txt",
    "processed_at": "2026-08-12T21:46:43.999873Z"
  }
}
```

---

## 🔧 Troubleshooting

### LocalStack Not Running
```bash
# Check container status
docker ps | grep localstack-lab

# Start if stopped
docker-compose up -d

# View logs
docker logs localstack-lab
```

### Lambda Endpoint Connection Issues
- **Issue:** Lambda can't reach LocalStack
- **Solution:** Environment variable `AWS_ENDPOINT_URL` uses `host.docker.internal:4566` (Docker-specific)
- Host scripts use `localhost:4566`

### S3 Event Notification Error
- **Issue:** "Unable to validate the following destination configurations"
- **Solution:** Ensure Lambda ARN is correct and Lambda has S3 invoke permission

### Python Virtual Environment Issues
```bash
# Deactivate and reactivate
deactivate
.\.venv\Scripts\Activate.ps1
pip install boto3
```

---

## 🔐 Security Notes

- **Test Credentials:** Uses dummy AWS access key ID (`test`) and secret key (`test`)
- **Endpoint:** LocalStack runs on `http://localhost:4566` (local only, not accessible externally)
- **IAM Policy:** Minimal permissions for demonstration purposes
- **Production:** Never use these credentials or configurations in production

---

## 📚 Key Files

### [localstack_event_pipeline.py](localstack_event_pipeline.py)
Master orchestration script that:
- Creates/validates AWS resources
- Packages and deploys Lambda functions
- Configures event notifications
- Executes end-to-end test

### [lambdas/event_processor.py](lambdas/event_processor.py)
First-stage Lambda that:
- Handles S3 events
- Extracts file metadata
- Invokes result-processor

### [lambdas/result_processor.py](lambdas/result_processor.py)
Second-stage Lambda that:
- Processes file metadata
- Transforms filename (uppercase)
- Returns final response

### [docker-compose.yml](docker-compose.yml)
Defines LocalStack container with:
- S3, Lambda, IAM, Logs services enabled
- Docker socket mounted for Lambda execution
- Health checks configured

---

## 🎯 Learning Objectives

This project demonstrates:
1. ✅ AWS S3 event notifications
2. ✅ Lambda function deployment and invocation
3. ✅ Inter-Lambda communication
4. ✅ IAM roles and permissions
5. ✅ CloudWatch Logs integration
6. ✅ Local AWS development with LocalStack
7. ✅ Docker-based Lambda execution
8. ✅ Event-driven architecture
9. ✅ Infrastructure as Code (IaC) concepts
10. ✅ Boto3 SDK usage

---

## 📞 Support

For issues or questions:
1. Check [Troubleshooting](#-troubleshooting) section
2. Review LocalStack logs: `docker logs localstack-lab`
3. Check Lambda logs in CloudWatch
4. Verify all prerequisites are installed

---

## 📄 License


