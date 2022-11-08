resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "function_logging_policy" {
  name = "function-logging-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowLogging",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Sid" : "AllowWritingToS3",
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*",
          "s3:Put*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.function_logging_policy.arn
}

resource "aws_lambda_function" "parse_csv_function" {
  filename      = "${path.module}/functions/parse-csv/src/parse-csv/bin/Release/net6.0/parse-csv.zip"
  function_name = "parse-csv"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "parse-csv::parse_csv.Function::FunctionHandler"
  runtime       = "dotnet6"
  timeout       = 10
  memory_size   = 512
  environment {
    variables = {
      foo = "bar"
    }
  }
  tags = {
    Name = var.tag_name
  }
}

resource "aws_lambda_permission" "S3_invoke_function" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.parse_csv_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.upload_bucket.id}"
}

# Adding S3 bucket as trigger to my lambda and giving the permissions
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.upload_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.parse_csv_function.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

data "archive_file" "zip_main_py" {
  type        = "zip"
  output_path = "${path.module}/functions/generate-pdf/main.zip"
  source_file = "${path.module}/functions/generate-pdf/handler.py"
}

data "archive_file" "lambda_layer_package" {
  type        = "zip"
  output_path = "${path.module}/functions/generate-pdf/pdfkit.zip"
  source_dir  = "${path.module}/functions/generate-pdf/"
}

# Create PDF Lambda Layer PDFKit
resource "aws_lambda_layer_version" "pdf_kit_lambda_layer" {
  filename            = "${path.module}/functions/generate-pdf/pdfkit.zip"
  layer_name          = "pdfkit"
  compatible_runtimes = ["python3.8", "python3.9"]
  depends_on = [
    data.archive_file.lambda_layer_package
  ]
}

# Create PDF Lambda Layer external binaries
resource "aws_lambda_layer_version" "wkhtml_lambda_layer" {
  filename            = "${path.module}/functions/Common/external/wkhtmltopdf.zip"
  layer_name          = "wkhtmltopdf"
  compatible_runtimes = ["python3.8", "python3.9"]
}

# Create PDF Lambda
resource "aws_lambda_function" "generate_pdf_lambda" {
  filename      = "${path.module}/functions/generate-pdf/main.zip"
  function_name = "generate-pdf-lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "handler.generate_pdf"
  runtime       = "python3.8"
  memory_size   = 128
  timeout       = 30
  layers = [
    resource.aws_lambda_layer_version.pdf_kit_lambda_layer.arn,
    resource.aws_lambda_layer_version.wkhtml_lambda_layer.arn,
    "arn:aws:lambda:us-east-1:828402573329:layer:wkhtmltopdf-custom:1"
  ]
  depends_on = [
    data.archive_file.zip_main_py,
    resource.aws_lambda_layer_version.pdf_kit_lambda_layer
  ]
  source_code_hash = data.archive_file.zip_main_py.output_base64sha256

  environment {
    variables = {
      S3_BUCKET_NAME  = "created-pdf-bucket",
      FONTCONFIG_PATH = "/opt/fonts"
    }
  }
}