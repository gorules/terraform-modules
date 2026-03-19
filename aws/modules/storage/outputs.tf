# S3 Bucket Outputs

output "bucket_name" {
  description = "Name of the S3 bucket for GoRules rules storage"
  value       = local.bucket_name
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for GoRules rules storage"
  value       = local.bucket_arn
}

output "bucket_id" {
  description = "ID of the S3 bucket (same as bucket_name for created buckets)"
  value       = local.create_bucket ? aws_s3_bucket.this[0].id : var.storage.existing_bucket_name
}

output "bucket_region" {
  description = "Region of the S3 bucket"
  value       = data.aws_region.current.id
}

# IAM Policy Outputs

output "iam_policy_arn" {
  description = "ARN of the IAM policy for full S3 access (read/write)"
  value       = aws_iam_policy.s3_access.arn
}

output "iam_policy_name" {
  description = "Name of the IAM policy for full S3 access"
  value       = aws_iam_policy.s3_access.name
}

output "iam_read_only_policy_arn" {
  description = "ARN of the IAM policy for read-only S3 access (for Agent)"
  value       = aws_iam_policy.s3_read_only.arn
}

output "iam_read_only_policy_name" {
  description = "Name of the IAM policy for read-only S3 access"
  value       = aws_iam_policy.s3_read_only.name
}

# Secrets Manager Outputs (when auth=secrets)

output "credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing S3 credentials (null if auth=iam)"
  value       = local.use_secrets ? aws_secretsmanager_secret.s3_credentials[0].arn : null
}

output "credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing S3 credentials (null if auth=iam)"
  value       = local.use_secrets ? aws_secretsmanager_secret.s3_credentials[0].name : null
}

# IAM User Outputs (when auth=secrets)

output "iam_user_arn" {
  description = "ARN of the IAM user for S3 access (null if auth=iam)"
  value       = local.use_secrets ? aws_iam_user.s3_access[0].arn : null
}

output "iam_user_name" {
  description = "Name of the IAM user for S3 access (null if auth=iam)"
  value       = local.use_secrets ? aws_iam_user.s3_access[0].name : null
}

# Configuration Outputs

output "auth_method" {
  description = "Authentication method used for S3 access (iam or secrets)"
  value       = var.storage.auth
}

output "versioning_enabled" {
  description = "Whether versioning is enabled on the S3 bucket"
  value       = local.create_bucket ? var.storage.versioning : null
}

output "cross_account_write_principals" {
  description = "AWS principals with cross-account write access"
  value       = var.cross_account_write_principals
}
