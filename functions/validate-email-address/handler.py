import json
import urllib.parse
import boto3
from datetime import datetime

ses_client = boto3.client("ses", region_name="us-east-1")
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('T4usersTable')

def update_item_verification_sent(table, record, value):
    table.update_item(
        Key={
            'usertype': record['dynamodb']['Keys']['usertype']['S'],
            'userId': record['dynamodb']['Keys']['userId']['S']
        },
        UpdateExpression="set verificationSent=:d",
        ExpressionAttributeValues={
            ':d': value
        }
    )

def validate(event, context):
    for record in event['Records']:
        if (record['eventName'] == "INSERT"):
            email_address = record['dynamodb']['NewImage']['useremail']['S'] # get email from insert body
        
            # Grab email address from this INSERT
            response = ses_client.verify_email_identity(
                EmailAddress=email_address
            )

            if response['ResponseMetadata']['HTTPStatusCode'] == 200:
                update_item_verification_sent(table, record, datetime.utcnow().isoformat())
            else:
                print('status back from ses was not good, writing default to verificationSent key')
                update_item_verification_sent(table, record, 'retry')
