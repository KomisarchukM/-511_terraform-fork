data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -----------------------------------------------------------------------------
# Security groups
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = var.alb_sg_name
  description = var.alb_sg_description

  tags = merge({ Name = var.alb_sg_name }, var.tags)
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP access from anywhere"
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "instances" {
  name        = var.instance_sg_name
  description = var.instance_sg_description

  tags = merge({ Name = var.instance_sg_name }, var.tags)
}

resource "aws_security_group_rule" "instances_http_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "HTTP access from the load balancer"
  security_group_id        = aws_security_group.instances.id
}

resource "aws_security_group_rule" "instances_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_ingress_cidr]
  description       = "SSH access"
  security_group_id = aws_security_group.instances.id
}

resource "aws_security_group_rule" "instances_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.instances.id
}

# -----------------------------------------------------------------------------
# Launch template
# -----------------------------------------------------------------------------

resource "aws_launch_template" "this" {
  name_prefix   = "${var.launch_template_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data = base64encode(<<-EOT
#!/bin/bash

apt-get update -y
apt-get install -y apache2 curl

systemctl start apache2
systemctl enable apache2

PRIVATE_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s ifconfig.me)

if [ -z "$PRIVATE_IP" ]; then
  PRIVATE_IP="Unavailable"
fi

if [ -z "$PUBLIC_IP" ]; then
  PUBLIC_IP="Unavailable"
fi

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Server IP Info</title>
</head>
<body>
    <h1>Public IP: $PUBLIC_IP</h1>
    <h1>Private IP: $PRIVATE_IP</h1>
</body>
</html>
EOF
EOT
  )

  # Note: launch templates are versioned, so a user_data change creates a new
  # template version and the ASG picks it up via "$Latest".

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instances.id]
  }

  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge({ Name = var.instance_name }, var.tags)
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge({ Name = var.instance_name }, var.tags)
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Load balancer, target group and listener
# -----------------------------------------------------------------------------

resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

  tags = merge({ Name = var.alb_name }, var.tags)
}

resource "aws_lb_target_group" "this" {
  name     = var.target_group_name
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path     = var.health_check_path
    port     = "traffic-port"
    protocol = "HTTP"
    matcher  = "200"
  }

  # Round-robin: no sticky sessions, so a reload may reach a different instance.
  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  tags = merge({ Name = var.target_group_name }, var.tags)
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# -----------------------------------------------------------------------------
# Autoscaling group
# -----------------------------------------------------------------------------

resource "aws_autoscaling_group" "this" {
  name                = var.asg_name
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = data.aws_subnets.default.ids

  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period
  wait_for_elb_capacity     = var.asg_desired_capacity
  target_group_arns         = [aws_lb_target_group.this.arn]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.asg_name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
