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
  default     = "team4sandbox2"
}