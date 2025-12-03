# lambda_src/lambda_generate.py
import os
import json
import time
import boto3
import hashlib
import random

dynamodb = boto3.client("dynamodb")
TABLE = os.environ.get("DYNAMODB_TABLE")

def _hash_otp(otp, secret):
    # simple HMAC-like mix (for dev). In prod use HMAC + Secrets Manager.
    return hashlib.sha256((otp + secret).encode("utf-8")).hexdigest()

def handler(event, context):
    try:
        body = event.get("body")
        if isinstance(body, str):
            body = json.loads(body)
        mobile = body.get("mobile")
        if not mobile:
            return {"statusCode": 400, "body": json.dumps({"error":"mobile required"})}

        # generate simple numeric OTP
        otp = "{:06d}".format(random.randint(0, 999999))
        secret = os.environ.get("OTP_SECRET", "")
        hashed = _hash_otp(otp, secret)

        ttl_seconds = int(os.environ.get("OTP_TTL_SECONDS", "300"))
        expiry = int(time.time()) + ttl_seconds  # epoch seconds for DynamoDB TTL

        # item stored with TTL attribute name 'expiry' (module default)
        dynamodb.put_item(
            TableName=TABLE,
            Item={
                "mobile_number": {"S": mobile},
                "otp_hash": {"S": hashed},
                "created_at": {"N": str(int(time.time()))},
                "expiry": {"N": str(expiry)}
            }
        )

        # In real systems send OTP via SMS here. Returning OTP only for dev/testing.
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "otp generated", "mobile": mobile, "otp": otp})
        }

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
