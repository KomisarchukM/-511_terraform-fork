variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name; a random 6-letter suffix is appended"
  type        = string
  default     = "homework-15-11-komism-"
}

variable "source_dir" {
  description = "Path to the local folder whose files are uploaded to the bucket"
  type        = string
}

variable "key_prefix" {
  description = "Optional S3 key prefix for uploaded objects; empty uploads to the bucket root"
  type        = string
  default     = ""
}

variable "expiration_days" {
  description = "Number of days after which current objects and noncurrent versions expire"
  type        = number
  default     = 3
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even if it still contains objects"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
