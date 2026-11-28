# HMP621 — Terraform AWS Demo

Terraform configuration that provisions Ubuntu EC2 instances with security
groups in AWS (`eu-north-1`), using the default VPC — including two web servers
behind an internet-facing Application Load Balancer.

## Structure

```
.
├── main.tf                 # terraform block, provider, module call
├── variables.tf            # input variables (secrets are sensitive)
├── outputs.tf              # instance_id, public_ip, private_ip, sg_id
├── terraform.tfvars          # non-secret values (gitignored, auto-loaded)
├── secrets.auto.tfvars       # AWS credentials (gitignored, auto-loaded, NEVER commit)
├── secrets.tfvars.example    # template for secrets
├── modules/
│   ├── demo-server/        # EC2 + security group + rules
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── web-alb/            # 2 EC2s + security groups + internet-facing ALB
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── web-asg/            # launch template + ALB + ASG (2–4 instances)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── web-bucket/         # static website S3 bucket hosting ./Web/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── pics-bucket/        # public S3 bucket for ./Pics/ with 3-day lifecycle
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── Web/                    # static website files uploaded by web-bucket
├── Pics/                   # image files uploaded by pics-bucket
├── AGENTS.md               # system prompt for the AI agent
└── README.md
```

## Module `modules/demo-server`

| Resource | Description |
|---|---|
| `aws_instance.this` | Ubuntu EC2, gp3 root volume (20 GB), IMDSv2 required |
| `aws_security_group.this` | `SG_Terraform` |
| `aws_security_group_rule.ingress` | `for_each` rules: SSH 22, HTTP 80, ICMP — all `0.0.0.0/0` |
| `aws_security_group_rule.egress` | all outbound `0.0.0.0/0` |

## Module `modules/web-alb`

Two Ubuntu web servers running Apache behind an internet-facing Application
Load Balancer in the default VPC. Each instance runs a `user_data` script that
installs Apache and serves an `index.html` showing its public and private IP.
Reloading the URL round-robins between the two instances.

| Resource | Description |
|---|---|
| `data.aws_vpc.default` / `data.aws_subnets.default` | Default VPC and its subnets (ALB needs ≥2 AZs) |
| `aws_security_group.alb` | `SG_Web_ALB` — HTTP 80 from `0.0.0.0/0` |
| `aws_security_group.instances` | `SG_Web_ALB_Instances` — HTTP 80 from the ALB SG only, SSH/ICMP `0.0.0.0/0` |
| `aws_security_group_rule.alb_ingress_http` / `.alb_egress` | ALB ingress/egress rules |
| `aws_security_group_rule.instances_*` | Instance ingress (HTTP from ALB, SSH, ICMP) + egress |
| `aws_instance.this` | 2× Ubuntu EC2 (`count = 2`), Apache via `user_data`, public IP, IMDSv2 required |
| `aws_lb.this` | Internet-facing application load balancer |
| `aws_lb_target_group.this` | HTTP target group, health check `GET /` → 200 |
| `aws_lb_listener.this` | Port 80 → forward to target group |
| `aws_lb_target_group_attachment.this` | Attaches both instances to the target group |

## Module `modules/web-asg`

An autoscaled web tier: a launch template feeds an autoscaling group
(min 2 / desired 2 / max 4) whose instances sit behind a non-sticky
internet-facing Application Load Balancer. Same Apache `user_data` page as
`web-alb`, so every reload may land on a different instance.

| Resource | Description |
|---|---|
| `data.aws_vpc.default` / `data.aws_subnets.default` | Default VPC and its subnets |
| `aws_security_group.alb` | `SG_Web_ASG_ALB` — HTTP 80 from `0.0.0.0/0` |
| `aws_security_group.instances` | `SG_Web_ASG_Instances` — HTTP 80 from the ALB SG only, SSH 22 from `var.ssh_ingress_cidr` |
| `aws_launch_template.this` | t3.micro Ubuntu, Apache via `user_data`, gp3 root volume, IMDSv2 required, public IP |
| `aws_lb.this` | Internet-facing application load balancer (`web-asg-alb`) |
| `aws_lb_target_group.this` | HTTP target group (`web-asg-tg`), health check `GET /` → 200, stickiness **disabled** (round-robin) |
| `aws_lb_listener.this` | Port 80 → forward to target group |
| `aws_autoscaling_group.this` | `web-asg`, min 2 / desired 2 / max 4, `health_check_type = "ELB"`, registers the target group |

## Module `modules/web-bucket`

Hosts the static website from `./Web/` in a publicly readable S3 bucket (`komisarchukm-<6 random letters>`).

| Resource | Description |
|---|---|
| `random_string.suffix` | 6-letter lowercase random suffix for globally unique bucket name |
| `aws_s3_bucket.this` | S3 bucket `komisarchukm-<suffix>` with `force_destroy = true` |
| `aws_s3_bucket_public_access_block.this` | Public access blocks disabled to allow public read policy |
| `aws_s3_bucket_policy.this` | Public `s3:GetObject` read policy on all bucket objects |
| `aws_s3_object.this` | Uploads `./Web/` files under the `Web/` prefix with MIME content types |

## Module `modules/pics-bucket`

Creates an unversioned, publicly readable S3 bucket (`homework-15-11-komism-<6 random letters>`) containing all files from `./Pics/` at the bucket root, with automatic 3-day expiration.

| Resource | Description |
|---|---|
| `random_string.suffix` | 6-letter lowercase random suffix for globally unique bucket name |
| `aws_s3_bucket.this` | Default unversioned S3 bucket `homework-15-11-komism-<suffix>` (`force_destroy = true`) |
| `aws_s3_bucket_public_access_block.this` | All public access blocks disabled (`false`) |
| `aws_s3_bucket_policy.this` | `PublicReadAllObjects` policy allowing `s3:GetObject` for `*` on `${aws_s3_bucket.this.arn}/*` |
| `aws_s3_bucket_lifecycle_configuration.this` | Expires current objects and noncurrent versions after 3 days |
| `aws_s3_object.this` | Uploads all `./Pics/` files to the bucket root with image content types |

## Prerequisites

- Terraform >= 1.5.0
- AWS account + access key (create a dedicated IAM user, prefer rotating keys)

## Setup

```powershell
# 1. Create secrets file from template (once)
Copy-Item secrets.tfvars.example secrets.auto.tfvars
# edit secrets.auto.tfvars and put real AWS credentials
# (`.auto.tfvars` is loaded by Terraform automatically - no -var-file needed)

# 2. Adjust non-secret settings if needed
notepad terraform.tfvars

# 3. Init & validate
terraform init
terraform validate
```

## Usage

```powershell
# Full infrastructure
terraform plan
terraform apply

# Only the demo-server module (quotes required in PowerShell)
terraform plan  "-target=module.demo_server"
terraform apply "-target=module.demo_server"

# Only the web-alb module (2 EC2s + load balancer)
terraform plan  "-target=module.web_alb"
terraform apply "-target=module.web_alb"

# Only the web-asg module (launch template + ALB + autoscaling group)
terraform plan  "-target=module.web_asg"
terraform apply "-target=module.web_asg"
```

## Outputs

After apply you get:

- `instance_id`
- `public_ip`
- `private_ip`
- `security_group_id`
- `web_bucket_name`
- `web_index_url`
- `pics_bucket_name`
- `pics_bucket_arn`
- `pics_object_urls`
- `web_alb_dns_name`
- `web_alb_url`
- `web_alb_instance_public_ips`
- `web_asg_url`
- `web_asg_alb_dns_name`
- `web_asg_name`
- `web_asg_instance_security_group_id`

```powershell
terraform output public_ip
terraform output web_alb_url
```

## Cleanup

```powershell
terraform destroy
```

## Security notes

- **`secrets.auto.tfvars` and `terraform.tfvars` are gitignored.** Never commit
  credentials. Copy `secrets.tfvars.example` to `secrets.auto.tfvars` instead.
- **Rotate the previously exposed access key** — credentials were once
  hardcoded in `vars.tf` and must be considered compromised.
- SSH/HTTP ingress is open to the whole internet (`0.0.0.0/0`) by explicit
  decision. Restrict `ingress_rules` (module input) if tighter access needed.
- IMDSv2 is enforced (`http_tokens = "required"`).

## Customization

| Variable | Default | Purpose |
|---|---|---|
| `aws_region` | `eu-north-1` | AWS region |
| `aws_image_id` | `ami-035c8a091035e710a` | AMI |
| `aws_instance_type` | `t3.small` | Instance type |
| `web_asg_instance_type` | `t3.micro` | Instance type for the autoscaled web tier |
| `aws_key_name` | `Stokholm` | EC2 key pair |
| `root_volume_size` | `20` | Root volume GB |
| `sg_name` | `SG_Terraform` | Security group name |
| `tags` | project tags | Common tags |
