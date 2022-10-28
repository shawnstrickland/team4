terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.region
}

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

resource "aws_lambda_function" "parse_csv_function" {
  filename      = "${path.module}/functions/parse-csv/src/parse-csv/bin/Release/net6.0/parse-csv.zip"
  function_name = "parse-csv"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "parse-csv::parse_csv.Function::FunctionHandler"
  runtime       = "dotnet6"
  environment {
    variables = {
      foo = "bar"
    }
  }
  tags = {
    Name = var.tag_name
  }
}