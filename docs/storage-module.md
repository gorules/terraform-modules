# Storage Module

S3 bucket for rule storage, IAM policies, and optional secrets-based auth.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | S3 bucket, encryption, versioning, lifecycle, cross-account policy |
| `iam.tf` | Read-write and read-only IAM policies |
| `secrets.tf` | IAM user + Secrets Manager for secrets auth mode |
| `variables.tf` | Input variables |
| `outputs.tf` | Module outputs |

## S3 Bucket Configuration (`main.tf`)

Bucket naming: `{name_prefix}-rules-{random_hex}` (8-char suffix for uniqueness)

| Resource | Purpose |
|----------|---------|
| `random_id.bucket_suffix` | 4 bytes → 8 hex chars |
| `aws_s3_bucket` | The rules storage bucket |
| `aws_s3_bucket_versioning` | Optional (default: enabled) |
| `aws_s3_bucket_server_side_encryption_configuration` | AES256 + bucket key |
| `aws_s3_bucket_public_access_block` | All 4 block options enabled |
| `aws_s3_bucket_lifecycle_configuration` | Aborts incomplete multipart after 7 days |

## Security Features

- **Encryption**: AES256 server-side encryption with bucket key enabled
- **Public access**: Fully blocked (all 4 settings)
- **Transport security**: Bucket policy denies `aws:SecureTransport = false`
- **Versioning**: Enabled by default for rule file history

## Authentication Modes

Two modes controlled by `storage.auth`:

### IAM Mode (default: `auth = "iam"`)

No IAM user created. ECS task roles get S3 access via [IAM Architecture](iam-architecture.md):
- **BRMS task role** → `s3_access` policy (read/write)
- **Agent task role** → `s3_read_only` policy (read only)

### Secrets Mode (`auth = "secrets"`)

Creates an IAM user with access keys stored in Secrets Manager:

| Resource | Purpose |
|----------|---------|
| `aws_iam_user.s3_access` | Dedicated IAM user for S3 |
| `aws_iam_access_key.s3_access` | Access key pair |
| `aws_secretsmanager_secret.s3_credentials` | Secret container |
| `aws_secretsmanager_secret_version` | JSON: access_key_id, secret_access_key, bucket_name, region |

See [Secrets Management](secrets-management.md) for how secrets are consumed.

## IAM Policies (`iam.tf`)

Two policies created for different access levels:

### Read-Write Policy (`s3_access`)

Used by BRMS — full access to manage rule files:

```hcl
data "aws_iam_policy_document" "s3_access" {
  statement {
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.this[0].arn]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
    ]
    resources = ["${aws_s3_bucket.this[0].arn}/*"]
  }
}
```

### Read-Only Policy (`s3_read_only`)

Used by Agent — can only read rules, never modify them:

```hcl
data "aws_iam_policy_document" "s3_read_only" {
  statement {
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.this[0].arn]
  }

  statement {
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["${aws_s3_bucket.this[0].arn}/*"]
  }
}
```

## Cross-Account Access

For [multi-environment deployments](deployment-patterns.md), the bucket can grant access to other AWS accounts:

```hcl
storage = {
  cross_account_write_principals = [
    "123456789012",  # Staging account ID
    "987654321098"   # Production account ID
  ]
}
```

This creates a bucket policy allowing ListBucket, GetObject, PutObject, DeleteObject for the specified principals.

## How Other Modules Use This

- [ECS Module](ecs-module.md) — Receives `bucket_name`, `bucket_arn`, IAM policy ARNs
- [IAM Architecture](iam-architecture.md) — Task roles get S3 policy attachments
- [Root Module](root-module.md) — Routes bucket name/ARN (created or existing) to ECS

## Key Variables

```hcl
storage = {
  create_bucket                  = true
  existing_bucket_arn            = null
  existing_bucket_name           = null
  auth                           = "iam"     # or "secrets"
  versioning                     = true
  cross_account_write_principals = []
}
```

Set `storage = null` to disable entirely.
