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

# Create S3 Full Access Policy
resource "aws_iam_policy" "s3_policy" {
  name        = "s3-policy"
  description = "Policy for allowing all S3 Actions"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}

# Create API Gateway Role
resource "aws_iam_role" "s3_api_gateyway_role" {
  name = "s3-api-gateyway-role"

  # Create Trust Policy for API Gateway
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
} 
  EOF
}

# Attach S3 Access Policy to the API Gateway Role
resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role       = aws_iam_role.s3_api_gateyway_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_api_gateway_rest_api" "MyS3" {
  name        = "MyS3"
  description = "API for S3 Integration"
}

resource "aws_api_gateway_resource" "Folder" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  parent_id   = aws_api_gateway_rest_api.MyS3.root_resource_id
  path_part   = "{folder}"
}

resource "aws_api_gateway_resource" "Item" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  parent_id   = aws_api_gateway_resource.Folder.id
  path_part   = "{item}"
}

resource "aws_api_gateway_method" "GetItem" {
  rest_api_id   = aws_api_gateway_rest_api.MyS3.id
  resource_id   = aws_api_gateway_resource.Item.id
  http_method   = "GET"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.path.folder" = true,
    "method.request.path.item"   = true,
  }
}

resource "aws_api_gateway_method" "PutItem" {
  rest_api_id   = aws_api_gateway_rest_api.MyS3.id
  resource_id   = aws_api_gateway_resource.Item.id
  http_method   = "PUT"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.path.folder" = true,
    "method.request.path.item"   = true,
  }
}

resource "aws_api_gateway_integration" "S3Integration" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method

  # Included because of this issue: https://github.com/hashicorp/terraform/issues/10501
  integration_http_method = "GET"

  request_parameters = {
    "integration.request.path.folder" = "method.request.path.folder",
    "integration.request.path.item"   = "method.request.path.item"
  }

  type = "AWS"

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri         = "arn:aws:apigateway:${var.region}:s3:path//{folder}/{item}"
  credentials = aws_iam_role.s3_api_gateyway_role.arn
}

resource "aws_api_gateway_integration" "S3IntegrationPut" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method

  # Included because of this issue: https://github.com/hashicorp/terraform/issues/10501
  integration_http_method = "PUT"

  request_parameters = {
    "integration.request.path.folder" = "method.request.path.folder",
    "integration.request.path.item"   = "method.request.path.item"
  }

  type = "AWS"

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri         = "arn:aws:apigateway:${var.region}:s3:path//{folder}/{item}"
  credentials = aws_iam_role.s3_api_gateyway_role.arn
}

resource "aws_api_gateway_method_response" "i200" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Disposition" = true
    "method.response.header.Content-Length"      = true
  }
}

resource "aws_api_gateway_method_response" "i400" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = "400"
}

resource "aws_api_gateway_method_response" "i500" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "i200IntegrationResponse" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = aws_api_gateway_method_response.i200.status_code

  response_parameters = {
    "method.response.header.Content-Disposition" = "integration.response.header.Content-Disposition"
    "method.response.header.Content-Length"      = "integration.response.header.Content-Length"
  }
}

resource "aws_api_gateway_integration_response" "i400IntegrationResponse" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = aws_api_gateway_method_response.i400.status_code

  selection_pattern = "4\\d{2}"
}

resource "aws_api_gateway_integration_response" "i500IntegrationResponse" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = aws_api_gateway_method_response.i500.status_code

  selection_pattern = "5\\d{2}"
}

resource "aws_api_gateway_method_response" "i200Put" {
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Disposition" = true
    "method.response.header.Content-Length"      = true
  }
}

resource "aws_api_gateway_method_response" "i400Put" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = "400"
}

resource "aws_api_gateway_method_response" "i500Put" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "i200IntegrationResponsePut" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = aws_api_gateway_method_response.i200.status_code

  response_parameters = {
    "method.response.header.Content-Disposition" = "integration.response.header.Content-Disposition"
    "method.response.header.Content-Length"      = "integration.response.header.Content-Length"
  }
}

resource "aws_api_gateway_integration_response" "i400IntegrationResponsePut" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = aws_api_gateway_method_response.i400.status_code

  selection_pattern = "4\\d{2}"
}

resource "aws_api_gateway_integration_response" "i500IntegrationResponsePut" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = aws_api_gateway_method_response.i500.status_code

  selection_pattern = "5\\d{2}"
}

resource "aws_api_gateway_deployment" "S3APIDeployment" {
  depends_on  = [aws_api_gateway_integration.S3Integration, aws_api_gateway_integration.S3IntegrationPut]
  rest_api_id = aws_api_gateway_rest_api.MyS3.id
  stage_name  = "MyS3"
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