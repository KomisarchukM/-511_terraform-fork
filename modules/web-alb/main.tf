data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

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
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SSH access"
  security_group_id = aws_security_group.instances.id
}

resource "aws_security_group_rule" "instances_icmp" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "ICMP ping"
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

resource "aws_instance" "this" {
  count = var.instance_count

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids      = [aws_security_group.instances.id]

  user_data = <<-EOT
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

  user_data_replace_on_change = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(
    { Name = "${var.instance_name}-${count.index + 1}" },
    var.tags,
  )
}

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

resource "aws_lb_target_group_attachment" "this" {
  count = var.instance_count

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.this[count.index].id
  port             = var.target_port
}
