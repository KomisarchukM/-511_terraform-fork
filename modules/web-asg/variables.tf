variable "ami_id" {
  description = "AMI ID for the autoscaled web server instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used by the launch template"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access to the instances"
  type        = string
}

variable "instance_name" {
  description = "Name tag applied to instances launched by the template"
  type        = string
  default     = "Web ASG Instance"
}

variable "launch_template_name" {
  description = "Name prefix for the launch template"
  type        = string
  default     = "web-asg-lt"
}

variable "root_device_name" {
  description = "Block device name for the root volume"
  type        = string
  default     = "/dev/sda1"
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
  default     = "web-asg-alb"
}

variable "alb_sg_name" {
  description = "Name of the security group for the load balancer"
  type        = string
  default     = "SG_Web_ASG_ALB"
}

variable "alb_sg_description" {
  description = "Description of the load balancer security group"
  type        = string
  default     = "Security group for the web-asg Application Load Balancer"
}

variable "instance_sg_name" {
  description = "Name of the security group for the autoscaled instances"
  type        = string
  default     = "SG_Web_ASG_Instances"
}

variable "instance_sg_description" {
  description = "Description of the autoscaled instance security group"
  type        = string
  default     = "Security group for the web servers behind the web-asg load balancer"
}

variable "ssh_ingress_cidr" {
  description = "CIDR block allowed to reach the instances over SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "target_group_name" {
  description = "Name of the target group"
  type        = string
  default     = "web-asg-tg"
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

variable "health_check_grace_period" {
  description = "Seconds the autoscaling group waits before health checks count against new instances"
  type        = number
  default     = 300
}

variable "asg_name" {
  description = "Name of the autoscaling group"
  type        = string
  default     = "web-asg"
}

variable "asg_min_size" {
  description = "Minimum number of instances in the autoscaling group"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the autoscaling group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in the autoscaling group"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
