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

output "launch_template_id" {
  description = "ID of the launch template used by the autoscaling group"
  value       = aws_launch_template.this.id
}

output "asg_name" {
  description = "Name of the autoscaling group"
  value       = aws_autoscaling_group.this.name
}

output "asg_instance_ids" {
  description = "IDs of the instances currently managed by the autoscaling group"
  value       = aws_autoscaling_group.this.instance_ids
}

output "alb_security_group_id" {
  description = "ID of the load balancer security group"
  value       = aws_security_group.alb.id
}

output "instance_security_group_id" {
  description = "ID of the autoscaled instance security group"
  value       = aws_security_group.instances.id
}
