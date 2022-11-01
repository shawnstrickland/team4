# Creating s3 resource for invoking to lambda function
resource "aws_s3_bucket" "upload_bucket" {
  bucket = "team-4-upload-bucket"
  acl    = "private"
  tags = {
    Name = var.tag_name
  }
}