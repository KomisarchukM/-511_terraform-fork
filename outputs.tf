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

output "pics_bucket_name" {
  description = "Name of the Pics S3 bucket"
  value       = module.pics_bucket.bucket_name
}

output "pics_bucket_arn" {
  description = "ARN of the Pics S3 bucket"
  value       = module.pics_bucket.bucket_arn
}

output "pics_object_urls" {
  description = "Public HTTPS URLs of uploaded Pics objects"
  value       = module.pics_bucket.object_urls
}

output "web_alb_dns_name" {
  description = "DNS name of the web Application Load Balancer"
  value       = module.web_alb.alb_dns_name
}

output "web_alb_url" {
  description = "HTTP URL of the web Application Load Balancer"
  value       = module.web_alb.alb_url
}

output "web_alb_instance_public_ips" {
  description = "Public IPs of the web instances behind the load balancer"
  value       = module.web_alb.public_ip
}

output "web_asg_url" {
  description = "HTTP URL of the autoscaled web Application Load Balancer"
  value       = module.web_asg.alb_url
}

output "web_asg_alb_dns_name" {
  description = "DNS name of the autoscaled web Application Load Balancer"
  value       = module.web_asg.alb_dns_name
}

output "web_asg_name" {
  description = "Name of the autoscaling group serving the web tier"
  value       = module.web_asg.asg_name
}

output "web_asg_instance_security_group_id" {
  description = "ID of the security group attached to the autoscaled instances"
  value       = module.web_asg.instance_security_group_id
}
