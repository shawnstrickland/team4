import json
import urllib.parse
import boto3

def validate(event, context):
    print('running lambda')
    for record in event['Records'].values():
        print(record.eventName)
        if (record.eventName == "INSERT"):
            print('should run logic over this INSERT')
            email_address=event.get('email_address')
            print("email address")
            print(email_address)
            ses_client = boto3.client("ses", region_name="us-east-1")
        
            response = ses_client.verify_email_identity(
                EmailAddress=email_address
            )
            print(response)
