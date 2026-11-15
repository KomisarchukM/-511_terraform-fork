output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "object_urls" {
  description = "Public HTTPS URLs of all uploaded objects"
  value = {
    for key, obj in aws_s3_object.this :
    key => "https://${aws_s3_bucket.this.bucket_regional_domain_name}/${obj.key}"
  }
}
