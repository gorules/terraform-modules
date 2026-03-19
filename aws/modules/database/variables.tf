# Required Variables

variable "name_prefix" {
  description = "Prefix for resource names (e.g., project-environment)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the database will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the database subnet group"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets in different AZs are required for Aurora."
  }
}

variable "min_capacity" {
  description = "Minimum Aurora Capacity Units (ACUs) for serverless scaling (0-256, use 0 for auto-pause)"
  type        = number

  validation {
    condition     = var.min_capacity >= 0 && var.min_capacity <= 256
    error_message = "min_capacity must be between 0 and 256 ACUs."
  }
}

variable "max_capacity" {
  description = "Maximum Aurora Capacity Units (ACUs) for serverless scaling (0.5-256)"
  type        = number

  validation {
    condition     = var.max_capacity >= 0.5 && var.max_capacity <= 256
    error_message = "max_capacity must be between 0.5 and 256 ACUs."
  }
}

# Optional Variables

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "17.4"
}

variable "instance_count" {
  description = "Number of Aurora instances to create"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1
    error_message = "instance_count must be at least 1."
  }
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "gorules_admin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.master_username))
    error_message = "master_username must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "database_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "gorules"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.database_name))
    error_message = "database_name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection for the cluster"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Number of days to retain backups (1-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 1 and 35 days."
  }
}

variable "seconds_until_auto_pause" {
  description = "Time in seconds before Aurora Serverless v2 pauses when idle (300-86400). Requires min_capacity = 0. Set to null to disable auto-pause."
  type        = number
  default     = null

  validation {
    condition     = var.seconds_until_auto_pause == null || (var.seconds_until_auto_pause >= 300 && var.seconds_until_auto_pause <= 86400)
    error_message = "seconds_until_auto_pause must be between 300 and 86400 seconds, or null to disable."
  }
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during the next maintenance window"
  type        = bool
  default     = false
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights for database instances"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Retention period for Performance Insights data (7 or 731 days)"
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "performance_insights_retention_period must be 7 or 731 days."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Authentication Configuration

variable "auth" {
  description = "Authentication method: 'secrets' (password via Secrets Manager) or 'iam' (IAM database authentication)"
  type        = string
  default     = "secrets"

  validation {
    condition     = contains(["secrets", "iam"], var.auth)
    error_message = "auth must be 'secrets' or 'iam'."
  }
}

variable "iam_username" {
  description = "Username for IAM database authentication (only used when auth='iam')"
  type        = string
  default     = "gorules_user"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.iam_username))
    error_message = "iam_username must start with a letter and contain only alphanumeric characters and underscores."
  }
}
