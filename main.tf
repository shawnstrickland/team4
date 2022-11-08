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

resource "aws_api_gateway_rest_api" "Team4Backend" {
  name        = "Team4Backend"
  description = "Team 4 Backend API"
}

resource "aws_api_gateway_resource" "Item" {
  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  parent_id   = aws_api_gateway_rest_api.Team4Backend.root_resource_id
  path_part   = "{item+}"
}

resource "aws_api_gateway_method" "GetItem" {
  rest_api_id   = aws_api_gateway_rest_api.Team4Backend.id
  resource_id   = aws_api_gateway_resource.Item.id
  http_method   = "GET"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.path.item" = true,
  }
}

resource "aws_api_gateway_method" "PutItem" {
  rest_api_id   = aws_api_gateway_rest_api.Team4Backend.id
  resource_id   = aws_api_gateway_resource.Item.id
  http_method   = "PUT"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.path.item"                  = true,
    "method.request.header.Content-Disposition" = true
    "method.request.header.Content-Type"        = true
  }
}

resource "aws_api_gateway_integration" "S3Integration" {
  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method

  # Included because of this issue: https://github.com/hashicorp/terraform/issues/10501
  integration_http_method = "GET"

  request_parameters = {
    "integration.request.path.item" = "method.request.path.item"
  }

  type = "AWS"

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri         = "arn:aws:apigateway:${var.region}:s3:path/${var.s3-csv-bucket}/{item}"
  credentials = aws_iam_role.s3_api_gateyway_role.arn
}

resource "aws_api_gateway_integration" "S3IntegrationPut" {
  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method

  # Included because of this issue: https://github.com/hashicorp/terraform/issues/10501
  integration_http_method = "PUT"

  request_parameters = {
    "integration.request.path.item"                  = "method.request.path.item"
    "integration.request.header.Content-Disposition" = "method.request.header.Content-Disposition"
    "integration.request.header.Content-Type"        = "method.request.header.Content-Type"
  }

  type = "AWS"

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri         = "arn:aws:apigateway:${var.region}:s3:path/${var.s3-csv-bucket}/{item}"
  credentials = aws_iam_role.s3_api_gateyway_role.arn
}

resource "aws_api_gateway_method_response" "i200" {
  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Disposition" = true
    "method.response.header.Content-Type"        = true
  }
}

resource "aws_api_gateway_method_response" "i400" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = "400"
}

resource "aws_api_gateway_method_response" "i500" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "i200IntegrationResponse" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = aws_api_gateway_method_response.i200.status_code

  response_parameters = {
    "method.response.header.Content-Disposition" = "integration.response.header.Content-Disposition"
    "method.response.header.Content-Type"        = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_integration_response" "i400IntegrationResponse" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = aws_api_gateway_method_response.i400.status_code

  selection_pattern = "4\\d{2}"
}

resource "aws_api_gateway_integration_response" "i500IntegrationResponse" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.GetItem.http_method
  status_code = aws_api_gateway_method_response.i500.status_code

  selection_pattern = "5\\d{2}"
}

resource "aws_api_gateway_method_response" "i200Put" {
  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Disposition" = true
    "method.response.header.Content-Type"        = true
  }
}

resource "aws_api_gateway_method_response" "i400Put" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = "400"
}

resource "aws_api_gateway_method_response" "i500Put" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "i200IntegrationResponsePut" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = aws_api_gateway_method_response.i200.status_code

  response_parameters = {
    "method.response.header.Content-Disposition" = "integration.response.header.Content-Disposition"
    "method.response.header.Content-Type"        = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_integration_response" "i400IntegrationResponsePut" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = aws_api_gateway_method_response.i400.status_code

  selection_pattern = "4\\d{2}"
}

resource "aws_api_gateway_integration_response" "i500IntegrationResponsePut" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  resource_id = aws_api_gateway_resource.Item.id
  http_method = aws_api_gateway_method.PutItem.http_method
  status_code = aws_api_gateway_method_response.i500.status_code

  selection_pattern = "5\\d{2}"
}

resource "aws_api_gateway_deployment" "S3APIDeployment" {
  depends_on  = [aws_api_gateway_integration.S3Integration, aws_api_gateway_integration.S3IntegrationPut]
  rest_api_id = aws_api_gateway_rest_api.Team4Backend.id
  stage_name  = "Team4Backend"
}

# Create a bucket and create folders/directories
resource "aws_s3_bucket" "bucket" {
  bucket = "team4s3bucket"
  acl    = "private"
}

resource "aws_s3_bucket_object" "images" {
  bucket       = "team4s3bucket"
  key          = "zodiacsignimages"
  content_type = "application/x-directory"
}

resource "aws_s3_bucket_object" "personal" {
  bucket       = "team4s3bucket"
  key          = "zodiacpersonalityimages"
  content_type = "application/x-directory"
}
resource "aws_s3_bucket_object" "pdfflyer" {
  bucket       = "team4s3bucket"
  key          = "pdfflyer"
  content_type = "application/x-directory"
}
resource "aws_s3_bucket_object" "csvfolder" {
  bucket       = "team4s3bucket"
  key          = "filetoimport"
  content_type = "application/x-directory"
}
resource "aws_s3_bucket_object" "discardfolder" {
  bucket       = "team4s3bucket"
  key          = "importedfiles"
  content_type = "application/x-directory"
}


# Dynamodb Tables

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "T4IMPFileList"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "ownerId"
  range_key      = "owneremail"

  attribute {
    name = "ownerId"
    type = "S"
  }
  attribute {
    name = "owneremail"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  global_secondary_index {
    name               = "T4ImpFilerowidIndex"
    hash_key           = "ownerId"
    range_key          = "owneremail"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["ownerId", "owneremail"]
  }

  tags = {
    Name        = "dynamodb-table-1-T4"
    Environment = "dev"
  }
}

# Zodiac sign table

resource "aws_dynamodb_table" "zodiac-dynamodb-table" {
  name           = "T4Zodiacable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "zodiacId"
  range_key      = "signimagepath"

  attribute {
    name = "zodiacId"
    type = "S"
  }
  attribute {
    name = "signimagepath"
    type = "S"
  }
  /*
  attribute {
    name = "personalityimagepath"
    type = "S"
  }
*/
  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  global_secondary_index {
    name               = "T4zodiacIndex"
    hash_key           = "zodiacId"
    range_key          = "signimagepath"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["zodiacId", "signimagepath"]
  }
  tags = {
    Name        = "dynamodb-table-2-T4"
    Environment = "dev"
  }
}


resource "aws_dynamodb_table" "imported-file-records-dynamodb-table" {
  name           = "T4ImpItemTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "impId"
  range_key      = "ownerId"

  attribute {
    name = "impId"
    type = "S"
  }
  attribute {
    name = "ownerId"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  global_secondary_index {
    name               = "T4ImpItemsIndex"
    hash_key           = "impId"
    range_key          = "ownerId"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["impId", "ownerId"]
  }
  tags = {
    Name        = "dynamodb-table-3-T4"
    Environment = "dev"
  }
}


# Flyer generated details maintained in the following table.
resource "aws_dynamodb_table" "flyer-generated-dynamodb-table" {
  name           = "T4flyerTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "flyerId"
  range_key      = "ownerId"

  attribute {
    name = "flyerId"
    type = "S"
  }
  attribute {
    name = "ownerId"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  global_secondary_index {
    name               = "T4FlyerItemsIndex"
    hash_key           = "flyerId"
    range_key          = "ownerId"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["flyerId", "ownerId"]
  }
  tags = {
    Name        = "dynamodb-table-4-T4"
    Environment = "dev"
  }
}

# Team4 users details provided here 
resource "aws_dynamodb_table" "users-dynamodb-table" {
  name           = "T4usersTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "userId"
  range_key      = "usertype"

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "usertype"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  global_secondary_index {
    name               = "T4UsersIndex"
    hash_key           = "userId"
    range_key          = "usertype"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["userId", "usertype"]
  }
  tags = {
    Name        = "dynamodb-table-5-T4"
    Environment = "dev"
  }
}

