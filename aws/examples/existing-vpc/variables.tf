# Required Variables

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
}

variable "brms_license_key_secret_arn" {
  description = "ARN of Secrets Manager secret containing GoRules license key"
  type        = string
}

# Existing VPC Configuration (Required)

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of existing private subnet IDs (at least 2, in different AZs)"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of existing public subnet IDs (at least 2, in different AZs)"
  type        = list(string)
}

# Optional Variables - Tags

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Storage Configuration

variable "storage_auth" {
  description = "S3 authentication method: 'iam' (recommended) or 'secrets'"
  type        = string
  default     = "iam"
}

# Database Configuration

variable "database_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17.4"
}

variable "database_instance_count" {
  description = "Number of Aurora instances"
  type        = number
  default     = 1
}

variable "database_min_capacity" {
  description = "Minimum ACU capacity (0-256)"
  type        = number
  default     = 0.5
}

variable "database_max_capacity" {
  description = "Maximum ACU capacity (0.5-256)"
  type        = number
  default     = 4
}

variable "database_seconds_until_auto_pause" {
  description = "Seconds before auto-pause when idle (300-86400, null to disable). Requires database_min_capacity = 0."
  type        = number
  default     = null
}

variable "database_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "database_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

# BRMS Configuration

variable "brms_image" {
  description = "Docker image for BRMS"
  type        = string
  default     = "gorules/brms:latest"
}

variable "brms_cpu" {
  description = "Fargate CPU units for BRMS"
  type        = number
  default     = 512
}

variable "brms_memory" {
  description = "Fargate memory in MB for BRMS"
  type        = number
  default     = 1024
}

variable "brms_min_count" {
  description = "Minimum number of BRMS tasks"
  type        = number
  default     = 1
}

variable "brms_max_count" {
  description = "Maximum number of BRMS tasks"
  type        = number
  default     = 4
}

variable "brms_alb_deletion_protection" {
  description = "Enable deletion protection for BRMS ALB"
  type        = bool
  default     = true
}

variable "brms_domain" {
  description = "Custom domain name for BRMS (required - BRMS requires HTTPS)"
  type        = string
}

variable "brms_certificate_arn" {
  description = "ACM certificate ARN for BRMS HTTPS (optional)"
  type        = string
  default     = null
}

variable "brms_route53_zone_id" {
  description = "Route53 zone ID for BRMS DNS (alternative to certificate_arn)"
  type        = string
  default     = null
}

variable "brms_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access BRMS ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "brms_env" {
  description = "Additional environment variables for BRMS"
  type        = list(object({ name = string, value = string }))
  default     = []
}

variable "brms_secrets" {
  description = "Additional secrets from Secrets Manager for BRMS"
  type        = list(object({ name = string, valueFrom = string }))
  default     = []
}

variable "brms_secrets_provider_type" {
  description = "Secrets provider type: 'env' (master key) or 'aws-kms'"
  type        = string
  default     = "env"
}

variable "brms_secrets_provider_master_key_length" {
  description = "Master key length for env provider (min 32)"
  type        = number
  default     = 64
}

variable "brms_secrets_provider_create_kms_key" {
  description = "Create new KMS key for aws-kms provider (set false to use existing)"
  type        = bool
  default     = true
}

variable "brms_secrets_provider_kms_key_arn" {
  description = "Existing KMS key ARN (required when create_kms_key=false)"
  type        = string
  default     = null
}

variable "brms_secrets_provider_kms_key_alias" {
  description = "Alias for created KMS key (optional)"
  type        = string
  default     = null
}

variable "brms_secrets_provider_kms_deletion_window" {
  description = "KMS key deletion window in days (7-30)"
  type        = number
  default     = 30
}

# BRMS AI/LLM Configuration

variable "brms_ai_enabled" {
  description = "Enable AI/LLM features for BRMS"
  type        = bool
  default     = false
}

variable "brms_ai_provider" {
  description = "LLM provider: openai, anthropic, google, amazon-bedrock, azure-openai"
  type        = string
  default     = "anthropic"
}

variable "brms_ai_model" {
  description = "LLM model name or inference profile ID (e.g., us.anthropic.claude-sonnet-4-6-v1:0). For amazon-bedrock, newer models require inference profile IDs with a geographic prefix."
  type        = string
  default     = "claude-sonnet-4-6"
}

variable "brms_ai_api_key_secret_arn" {
  description = "Secrets Manager ARN containing the LLM API key (not needed for amazon-bedrock)"
  type        = string
  default     = null
}

variable "brms_ai_temperature" {
  description = "LLM sampling temperature (0-2)"
  type        = number
  default     = 0.4
}

variable "brms_ai_thinking_level" {
  description = "LLM thinking level: high, medium"
  type        = string
  default     = "medium"
}

variable "brms_external_buckets" {
  description = "External S3 buckets for cross-account deployments"
  type = list(object({
    arn  = string
    name = string
  }))
  default = []
}

# Agent Configuration

variable "agent_image" {
  description = "Docker image for Agent"
  type        = string
  default     = "gorules/agent:latest"
}

variable "agent_cpu" {
  description = "Fargate CPU units for Agent"
  type        = number
  default     = 256
}

variable "agent_memory" {
  description = "Fargate memory in MB for Agent"
  type        = number
  default     = 512
}

variable "agent_min_count" {
  description = "Minimum number of Agent tasks"
  type        = number
  default     = 1
}

variable "agent_max_count" {
  description = "Maximum number of Agent tasks"
  type        = number
  default     = 10
}

variable "agent_alb_deletion_protection" {
  description = "Enable deletion protection for Agent ALB"
  type        = bool
  default     = true
}

variable "agent_domain" {
  description = "Custom domain name for Agent (optional)"
  type        = string
  default     = null
}

variable "agent_certificate_arn" {
  description = "ACM certificate ARN for Agent HTTPS (optional)"
  type        = string
  default     = null
}

variable "agent_route53_zone_id" {
  description = "Route53 zone ID for Agent DNS (alternative to certificate_arn)"
  type        = string
  default     = null
}

variable "agent_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Agent ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "agent_env" {
  description = "Additional environment variables for Agent"
  type        = list(object({ name = string, value = string }))
  default     = []
}

variable "agent_secrets" {
  description = "Additional secrets from Secrets Manager for Agent"
  type        = list(object({ name = string, valueFrom = string }))
  default     = []
}
