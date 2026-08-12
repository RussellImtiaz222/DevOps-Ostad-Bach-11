import json
from datetime import datetime


def lambda_handler(event, context):
    file_name = event.get("file_name", "unknown")
    file_extension = event.get("file_extension", "")
    bucket_name = event.get("bucket", "unknown-bucket")
    key = event.get("key", "unknown-key")
    status_message = f"File '{file_name}' was successfully processed from bucket '{bucket_name}'."

    response = {
        "status": "ok",
        "message": status_message,
        "file_name_upper": file_name.upper(),
        "file_extension": file_extension,
        "bucket": bucket_name,
        "key": key,
        "processed_at": datetime.utcnow().isoformat() + "Z",
        "custom_message": "Processing complete via LocalStack Lambda chain."
    }
    return response
