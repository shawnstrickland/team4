# Creating s3 resource for invoking to lambda function
resource "aws_s3_bucket" "upload_bucket" {
  bucket = "team-4-upload-bucket"
  acl    = "private"
  tags = {
    Name = var.tag_name
  }
}

# Creating s3 resource for storing generated PDFs
resource "aws_s3_bucket" "created_pdf_bucket" {
  bucket = var.created_pdf_bucket
  acl    = "private"
  tags = {
    Name = var.tag_name
  }
}

# Creating s3 resource for PDF html templates
resource "aws_s3_bucket" "pdf_template_bucket" {
  bucket = var.pdf_template_bucket
  acl    = "private"
  tags = {
    Name = var.tag_name
  }
}