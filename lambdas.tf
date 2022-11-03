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
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
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

# data "archive_file" "lambda_layer_zip" {
#   type        = "zip"
#   output_path = "lambda_layer.zip"
#   source_dir  = "${path.module}/functions/create-pdf/nodejs/node-modules"
# }

# # Create PDF Lambda Layer
# resource "aws_lambda_layer_version" "create_pdf_layer_version" {
#   filename            = "${path.module}/functions/create-pdf/nodejs/lambda_layer.zip"
#   layer_name          = "create_pdf_lambda_layer"
#   compatible_runtimes = ["nodejs16.x"]
#   depends_on = [
#     data.archive_file.lambda_layer_zip
#   ]
# }

# Create PDF Lambda
# resource "aws_lambda_function" "create_pdf_lambda" {
#   filename      = "${path.module}/functions/create-pdf/nodejs/index.js"
#   function_name = "create_pdf_flyer"
#   role          = aws_iam_role.iam_for_lambda.arn
#   handler       = "index.handler"
#   layers        = [aws_lambda_layer_version.create_pdf_layer_version.arn]
#   runtime       = "nodejs16.x"
#   timeout       = 5
#   environment {
#     variables = {
#       FONTCONFIG_PATH = "/opt",
#       LD_LIBRARY_PATH = "/opt"
#     }
#   }
#   depends_on = [
#     aws_lambda_layer_version.create_pdf_layer_version
#   ]
# }
