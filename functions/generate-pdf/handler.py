import json
import pdfkit
import boto3
import os
client = boto3.client('s3')
import base64

# Get the bucket name environment variables to use in our code
S3_BUCKET_NAME = os.environ.get('S3_BUCKET_NAME')

def generate_pdf(event, context):

    name = event['name']
    sign = event['sign']
    date = event['date']

    # TODO: determine sign from date
    # TODO: search for pre-existing celebrity
    # TODO: add images for each sign, swap with dictionary for urls/encoding

    # Encode background image to avoid GET
    encoded_string = 'data:image/jpeg;base64,'
    with open("./background.jpg", "rb") as image_file:
        encoded_string += base64.b64encode(image_file.read()).decode()

        
    # Encode regular font
    encoded_font = 'data:font/truetype;charset=utf-8;base64,'
    with open("./AmaticSC-Regular.ttf", "rb") as image_file:
        encoded_font += base64.b64encode(image_file.read()).decode()

    # Encode bold font
    encoded_font_bold = 'data:font/truetype;charset=utf-8;base64,'
    with open("./Amatic-Bold.ttf", "rb") as image_file:
        encoded_font_bold += base64.b64encode(image_file.read()).decode()

    # Defaults
    key = f'{name}-{sign}.pdf'
    html = f'''
<!DOCTYPE html>
<html>
<head>
<style>
    @font-face {{
        font-family: 'Bold';
        font-style: normal;
        font-weight: normal;
        src: url('{encoded_font_bold}') format("truetype");
    }}

    @font-face {{
        font-family: 'Regular';
        font-style: normal;
        font-weight: normal;
        src: url('{encoded_font}') format("truetype");
    }}

    body {{
        background: url('{encoded_string}') no-repeat center center fixed;
        background-size: cover;
        color: white;
        min-height: 1395px;
        font-family: 'Regular';
        font-size: 2em;
    }}

    h1 {{
        padding-top: 100px;
        font-size: 7em;
        font-family: 'Bold';
    }}

    .centered {{
        text-align: center;
        width: 100%;
        margin: 0 auto;
    }}
</style>
</head>

<body>
    <div class="centered">
        <h1>{name}</h1>
        <h2>{date}</h2>
        <img src="http://dummyimage.com/600x400/ffffff/c1c3d9.png&text={sign}">
    </div>
</body>

</html>
        '''
    
    # TODO: Validate filename and html exist
    # TODO: Clean the filename
    # TODO: Add .pdf extension if necessary
    # TODO: Add a UUID to the key

    # Decode json and set values for our pdf    
    if 'body' in event:
        data = json.loads(event['body'])
        key = data['filename']
        html = data['html'] 

    # Set file path to save pdf on lambda first (temporary storage)
    filepath = '/tmp/{key}'.format(key=key)
    
    # Create PDF
    config = pdfkit.configuration(wkhtmltopdf="/opt/python/wkhtmltopdf/bin/wkhtmltopdf")
    pdfkit.from_string(html, filepath, configuration=config, options={
        'page-size':'A4',
        'margin-top': '0',
        'margin-right': '0',
        'margin-bottom': '0',
        'margin-left': '0',
    })
    

    # Upload to S3 Bucket
    r = client.put_object(
        Body=open(filepath, 'rb'),
        ContentType='application/pdf',
        Bucket=S3_BUCKET_NAME,
        Key=key,
    )
    
    # Format the PDF URI
    object_url = "https://{0}.s3.amazonaws.com/{1}".format(S3_BUCKET_NAME, key)

    # Response with result
    response = {
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Credentials": True,
        },
        "statusCode": 200,
        "body": object_url
    }

    return response