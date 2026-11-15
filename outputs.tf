output "instance_id" {
  description = "IDs of the EC2 instances"
  value       = module.demo_server.instance_id
}

output "public_ip" {
  description = "Public IPs of the EC2 instances"
  value       = module.demo_server.public_ip
}

output "private_ip" {
  description = "Private IPs of the EC2 instances"
  value       = module.demo_server.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.demo_server.security_group_id
}

output "web_index_url" {
  description = "Public HTTPS URL of the uploaded Web/index.html"
  value       = module.web_bucket.index_url
}

output "web_bucket_name" {
  description = "Name of the static Web S3 bucket"
  value       = module.web_bucket.bucket_name
}
