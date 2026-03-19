locals {
  create_bucket = var.storage.create_bucket
  use_secrets   = var.storage.auth == "secrets"

  bucket_name = local.create_bucket ? aws_s3_bucket.this[0].id : var.storage.existing_bucket_name
  bucket_arn  = local.create_bucket ? aws_s3_bucket.this[0].arn : var.storage.existing_bucket_arn

  common_tags = merge(var.tags, {
    Module = "storage"
  })
}

resource "random_id" "bucket_suffix" {
  count = local.create_bucket ? 1 : 0

  byte_length = 4
}

resource "aws_s3_bucket" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = "${var.name_prefix}-rules-${random_id.bucket_suffix[0].hex}"

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-rules-${random_id.bucket_suffix[0].hex}"
  })
}

resource "aws_s3_bucket_versioning" "this" {
  count = local.create_bucket && var.storage.versioning ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "cross_account" {
  count  = local.create_bucket && length(var.cross_account_write_principals) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.this[0].arn,
          "${aws_s3_bucket.this[0].arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid    = "CrossAccountBucketAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            for p in var.cross_account_write_principals :
            can(regex("^[0-9]{12}$", p)) ? "arn:aws:iam::${p}:root" : p
          ]
        }
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.this[0].arn
        Condition = {
          Bool = { "aws:SecureTransport" = "true" }
        }
      },
      {
        Sid    = "CrossAccountObjectAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            for p in var.cross_account_write_principals :
            can(regex("^[0-9]{12}$", p)) ? "arn:aws:iam::${p}:root" : p
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ]
        Resource = "${aws_s3_bucket.this[0].arn}/*"
        Condition = {
          Bool = { "aws:SecureTransport" = "true" }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}
