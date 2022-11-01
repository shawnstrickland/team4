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
  timeout       = 5
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