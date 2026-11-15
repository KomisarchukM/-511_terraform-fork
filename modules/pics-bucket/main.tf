resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = false
  special = false
}

resource "aws_s3_bucket" "this" {
  bucket        = "${var.bucket_prefix}${random_string.suffix.result}"
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "public_read" {
  statement {
    sid       = "PublicReadAllObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.public_read.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-objects-and-noncurrent-versions"
    status = "Enabled"

    filter {}

    expiration {
      days = var.expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.expiration_days
    }
  }
}

locals {
  content_types = {
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    png  = "image/png"
    gif  = "image/gif"
    webp = "image/webp"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
    bmp  = "image/bmp"
  }

  pic_files = {
    for file in fileset(var.source_dir, "**") :
    file => file if !endswith(file, ".DS_Store")
  }
}

resource "aws_s3_object" "this" {
  for_each     = local.pic_files
  bucket       = aws_s3_bucket.this.id
  key          = var.key_prefix != "" ? "${trimsuffix(var.key_prefix, "/")}/${each.key}" : each.key
  source       = "${var.source_dir}/${each.key}"
  etag         = filemd5("${var.source_dir}/${each.key}")
  content_type = try(local.content_types[lower(split(".", each.key)[length(split(".", each.key)) - 1])], "application/octet-stream")

  tags = var.tags
}
