# HMP621 — Terraform AWS Demo

Terraform configuration that provisions a single Ubuntu EC2 instance with a
security group in AWS (`eu-north-1`), using the default VPC.

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
│   ├── demo-server/        # single module: EC2 + security group + rules
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

```powershell
terraform output public_ip
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
| `aws_image_id` | `ami-0d6d8576c5ce37b8a` | AMI |
| `aws_instance_type` | `t3.small` | Instance type |
| `aws_key_name` | `Stockholm_3` | EC2 key pair |
| `root_volume_size` | `20` | Root volume GB |
| `sg_name` | `SG_Terraform` | Security group name |
| `tags` | project tags | Common tags |
