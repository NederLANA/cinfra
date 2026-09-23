import json

def handler(event, context):
    body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        import base64
        body = base64.b64decode(body).decode("utf-8")

    try:
        json.loads(body)
        valid = True
    except (json.JSONDecodeError, TypeError):
        valid = False

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"valid": valid})
    }