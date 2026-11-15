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

locals {
  content_types = {
    html        = "text/html"
    htm         = "text/html"
    css         = "text/css"
    js          = "text/javascript"
    json        = "application/json"
    png         = "image/png"
    jpg         = "image/jpeg"
    jpeg        = "image/jpeg"
    gif         = "image/gif"
    svg         = "image/svg+xml"
    ico         = "image/x-icon"
    txt         = "text/plain"
    php         = "text/plain"
    scss        = "text/plain"
    woff        = "font/woff"
    woff2       = "font/woff2"
    webmanifest = "application/manifest+json"
  }

  web_files = {
    for file in fileset(var.source_dir, "**") :
    file => file if !endswith(file, ".DS_Store")
  }
}

resource "aws_s3_object" "this" {
  for_each     = local.web_files
  bucket       = aws_s3_bucket.this.id
  key          = "Web/${each.key}"
  source       = "${var.source_dir}/${each.key}"
  etag         = filebase64sha256("${var.source_dir}/${each.key}")
  content_type = try(local.content_types[lower(split(".", each.key)[length(split(".", each.key)) - 1])], "application/octet-stream")

  tags = var.tags
}
