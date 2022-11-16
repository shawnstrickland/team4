import json
import urllib.parse
import boto3

def lambda_handler(event, context):
    email_address=event.get('email_address')
    first_name=event.get('first_name')
    last_name=event.get('last_name')
    url_click=event.get('url_click')
    ses_client = boto3.client("ses", region_name="us-east-1")
    CHARSET = "UTF-8"

    response = ses_client.send_email(
        Destination={
            "ToAddresses": [
                email_address,
            ],
        },
        Message={
            "Body": {
                "Text": {
                    "Charset": CHARSET,
                    "Data":"Hello "+ first_name +" " + last_name + "\n"
                    "Please find below link to your profile and flyer based on your date of birth" + "\n" +
                    url_click, 
                }
            },
            "Subject": {
                "Charset": CHARSET,
                "Data": "Astroyogi Profile",
            },
        },
        Source="sjstrick@me.com",
    )
