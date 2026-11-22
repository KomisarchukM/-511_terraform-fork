variable "ami_id" {
  description = "AMI ID for the web server instances"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to place behind the load balancer"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "instance_name" {
  description = "Name tag prefix for the instances"
  type        = string
  default     = "Web Instance"
}

variable "associate_public_ip_address" {
  description = "Whether to assign a public IP to the instances (required for outbound internet in the default VPC)"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "web-alb"
}

variable "alb_sg_name" {
  description = "Name of the security group for the load balancer"
  type        = string
  default     = "SG_Web_ALB"
}

variable "alb_sg_description" {
  description = "Description of the load balancer security group"
  type        = string
  default     = "Security group for the web Application Load Balancer"
}

variable "instance_sg_name" {
  description = "Name of the security group for the web instances"
  type        = string
  default     = "SG_Web_ALB_Instances"
}

variable "instance_sg_description" {
  description = "Description of the web instance security group"
  type        = string
  default     = "Security group for the web servers behind the load balancer"
}

variable "target_group_name" {
  description = "Name of the target group"
  type        = string
  default     = "web-target-group"
}

variable "target_port" {
  description = "Port the target group and listener forward to on the instances"
  type        = number
  default     = 80
}

variable "listener_port" {
  description = "Port the load balancer listener accepts traffic on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used for target group health checks"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
