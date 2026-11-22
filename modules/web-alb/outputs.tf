output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_url" {
  description = "HTTP URL of the Application Load Balancer"
  value       = "http://${aws_lb.this.dns_name}"
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.this.arn
}

output "instance_id" {
  description = "IDs of the web server instances"
  value       = aws_instance.this[*].id
}

output "public_ip" {
  description = "Public IPs of the web server instances"
  value       = aws_instance.this[*].public_ip
}

output "private_ip" {
  description = "Private IPs of the web server instances"
  value       = aws_instance.this[*].private_ip
}

output "security_group_id" {
  description = "ID of the web instance security group"
  value       = aws_security_group.instances.id
}

output "alb_security_group_id" {
  description = "ID of the load balancer security group"
  value       = aws_security_group.alb.id
}
