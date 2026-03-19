variable "name_prefix" {
  description = "Prefix for resource naming (e.g., gorules-prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "storage" {
  description = <<-EOT
    S3 storage configuration for GoRules rules.

    Options:
    - create_bucket: Create a new S3 bucket (default: true)
    - existing_bucket_arn: ARN of existing bucket (required if create_bucket=false)
    - existing_bucket_name: Name of existing bucket (required if create_bucket=false)
    - auth: Authentication method - "iam" (recommended) or "secrets" (default: "iam")
    - versioning: Enable S3 versioning (default: true)
  EOT
  type = object({
    create_bucket        = optional(bool, true)
    existing_bucket_arn  = optional(string)
    existing_bucket_name = optional(string)
    auth                 = optional(string, "iam")
    versioning           = optional(bool, true)
  })

  validation {
    condition     = contains(["iam", "secrets"], var.storage.auth)
    error_message = "storage.auth must be 'iam' or 'secrets'."
  }

  validation {
    condition = var.storage.create_bucket == true || (
      var.storage.existing_bucket_arn != null && var.storage.existing_bucket_name != null
    )
    error_message = "When create_bucket=false, both existing_bucket_arn and existing_bucket_name are required."
  }

  validation {
    condition     = var.storage.existing_bucket_arn == null || can(regex("^arn:aws:s3:::", var.storage.existing_bucket_arn))
    error_message = "existing_bucket_arn must be a valid S3 bucket ARN."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cross_account_write_principals" {
  description = <<-EOT
    AWS principals allowed cross-account write access to this bucket.

    RECOMMENDED: Use specific IAM role ARNs for least-privilege access:
      ["arn:aws:iam::123456789012:role/gorules-dev-brms-task"]

    WARNING: 12-digit account IDs are supported but grant access to ALL
    principals in that account, which may be overly permissive.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for p in var.cross_account_write_principals :
      can(regex("^[0-9]{12}$", p)) || can(regex("^arn:aws(-us-gov|-cn)?:iam::[0-9]{12}:role/.+$", p))
    ])
    error_message = "Each entry must be a 12-digit AWS account ID or a valid IAM role ARN."
  }
}
