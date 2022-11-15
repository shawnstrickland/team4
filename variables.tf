variable "tag_name" {
  description = "Value of the Name tag for all resources"
  type        = string
  default     = "Team4"
}

variable "region" {
  description = "Region for Cloud Challenge Apps"
  type        = string
  default     = "us-east-1"
}

variable "s3-csv-bucket" {
  description = "S3 Bucket used to reference Excel files uploaded by user"
  type        = string
  default     = "team-4-upload-bucket"
}

variable "created_pdf_bucket" {
  description = "Bucket that stores created PDFs from Lambda"
  type        = string
  default     = "created-pdf-bucket"
}

variable "pdf_template_bucket" {
  description = "Bucket that stores PDF to HTML templates for Lambda"
  type        = string
  default     = "team-4-pdf-template-bucket"
}

variable "users_table" {
  description = "Defined users table for app"
  type        = string
  default     = "T4usersTable"
}