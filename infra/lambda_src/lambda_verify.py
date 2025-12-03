# lambda_src/lambda_verify.py
import os
import json
import time
import boto3
import hashlib

dynamodb = boto3.client("dynamodb")
TABLE = os.environ.get("DYNAMODB_TABLE")

def _hash_otp(otp, secret):
    return hashlib.sha256((otp + secret).encode("utf-8")).hexdigest()

def handler(event, context):
    try:
        body = event.get("body")
        if isinstance(body, str):
            body = json.loads(body)
        mobile = body.get("mobile")
        otp = body.get("otp")
        if not mobile or not otp:
            return {"statusCode": 400, "body": json.dumps({"error":"mobile and otp required"})}

        resp = dynamodb.get_item(
            TableName=TABLE,
            Key={"mobile_number": {"S": mobile}},
            ConsistentRead=True
        )

        item = resp.get("Item")
        if not item:
            return {"statusCode": 404, "body": json.dumps({"message":"no otp found"})}

        secret = os.environ.get("OTP_SECRET", "")
        expected_hash = item.get("otp_hash", {}).get("S", "")
        provided_hash = _hash_otp(otp, secret)

        if provided_hash != expected_hash:
            return {"statusCode": 401, "body": json.dumps({"message":"invalid otp"})}

        # optionally delete the item after successful verification
        dynamodb.delete_item(
            TableName=TABLE,
            Key={"mobile_number": {"S": mobile}}
        )

        return {"statusCode": 200, "body": json.dumps({"message":"otp verified"})}

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
