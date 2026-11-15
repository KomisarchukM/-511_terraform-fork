variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name; a random 6-letter suffix is appended"
  type        = string
  default     = "komisarchukm-"
}

variable "source_dir" {
  description = "Path to the local folder whose files are uploaded under the Web/ prefix"
  type        = string
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
