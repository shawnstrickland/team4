import json
import urllib.parse
import boto3

ses_client = boto3.client("ses", region_name="us-east-1")

CHARSET = "UTF-8"

def send_email(message, messageAttributes):
    email_addresses = message['emailAddresses']
    first_name = message['firstName']
    last_name= message['lastName']
    url_click= message['url']
    
    response = ses_client.send_email(
        Destination={
            "ToAddresses": email_addresses
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
                "Data": "Cloud Challenge App - Update",
            },
        },
        Source="sjstrick@me.com",
    )

    print(response)

def lambda_handler(event, context):
    for record in event['Records']:
        # todo: for each notification, grab the contacts that need to be updated

        # todo: pull out any contacts which are not validated yet

        # send an email notification to each contact
        type = record['Sns']['Type']
        subject = record['Sns']['Subject']
        message = json.loads(record['Sns']['Message'])
        messageAttributes = record['Sns']['MessageAttributes']
        if subject == 'EmailUpdate':
            print('sending EmailUpdate...')
            send_email(message, messageAttributes)
        else:
            print('not sending message since subject wasn\'t for emailed updates.')

    
