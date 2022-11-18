    message = {
        "month": "october",
        "day": 2,
        "name": "Shawn"
    }

    snsResponse = sns.publish(
        TargetArn='arn:aws:sns:us-east-1:828402573329:send-process-update-notification',
        Message=json.dumps({'default': json.dumps(message) }),
        Subject='EmailUpdate',
        MessageStructure='json'
    )