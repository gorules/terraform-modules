# Required Variables

variable "name_prefix" {
  description = "Prefix for resource naming (e.g., gorules-prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "vpc_id" {
  description = "ID of the VPC where ECS resources will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 1
    error_message = "At least 1 private subnet is required for ECS tasks."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for internet-facing Application Load Balancers. May be empty when every ALB uses the internal scheme (alb_internal = true)."
  type        = list(string)
  default     = []
}

# BRMS Configuration

variable "brms" {
  description = "BRMS deployment configuration. Set to null to disable. See the wiki for fields."
  type = object({
    license_key_secret_arn    = string
    image                     = optional(string, "gorules/brms:latest")
    cpu                       = number
    memory                    = number
    port                      = optional(number, 80)
    min_count                 = optional(number, 1)
    max_count                 = number
    cpu_target                = optional(number, 60)
    health_check_path         = optional(string, "/api/health")
    health_check_grace_period = optional(number, 60)
    domain                    = string
    certificate_arn           = optional(string)
    route53_zone_id           = optional(string)
    allowed_cidr_blocks       = list(string)
    enable_execute_command    = optional(bool, false)
    deregistration_delay      = optional(number, 30)
    alb_deletion_protection   = optional(bool, true)
    alb_internal              = optional(bool, false)
    alb_http_only             = optional(bool, false)
    alb_idle_timeout          = optional(number, 60)
    env                       = optional(list(object({ name = string, value = string })), [])
    secrets                   = optional(list(object({ name = string, valueFrom = string })), [])
    secrets_provider = optional(object({
      type                = optional(string, "env") # "env" or "aws-kms"
      master_key_length   = optional(number, 64)    # Min 32, for env provider
      create_kms_key      = optional(bool, true)    # Create new or use existing
      kms_key_arn         = optional(string)        # Required if create_kms_key=false
      kms_key_alias       = optional(string)        # Optional alias for created key
      kms_deletion_window = optional(number, 30)    # 7-30 days
    }), { type = "env" })
    ai = optional(object({
      provider            = string
      model               = string
      api_key_secret_arn  = optional(string)
      temperature         = optional(number, 0.4)
      context_window      = optional(number)
      max_output_tokens   = optional(number, 32000)
      thinking_level      = optional(string, "medium")
      azure_resource_name = optional(string)
    }))
  })
  default = null

  validation {
    condition     = var.brms == null || contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.brms.cpu)
    error_message = "brms.cpu must be a valid Fargate CPU value: 256, 512, 1024, 2048, 4096, 8192, or 16384."
  }

  validation {
    condition     = var.brms == null || var.brms.min_count <= var.brms.max_count
    error_message = "brms.min_count must be less than or equal to brms.max_count."
  }

  validation {
    condition = var.brms == null || var.brms.alb_http_only || (
      var.brms.route53_zone_id != null || var.brms.certificate_arn != null
    )
    error_message = "BRMS requires HTTPS. Provide route53_zone_id or certificate_arn. Alternatively set alb_http_only = true when a trusted edge such as CloudFront terminates TLS."
  }

  validation {
    condition     = var.brms == null || !var.brms.alb_http_only || var.brms.alb_internal
    error_message = "brms.alb_http_only requires brms.alb_internal = true. An HTTP-only ALB must be internal and sit behind a TLS-terminating edge such as CloudFront."
  }

  validation {
    condition     = var.brms == null || (var.brms.alb_idle_timeout >= 1 && var.brms.alb_idle_timeout <= 4000)
    error_message = "brms.alb_idle_timeout must be between 1 and 4000 seconds."
  }

  validation {
    condition     = var.brms == null || var.brms.ai == null || var.brms.ai.provider != "amazon-bedrock" || can(regex("^(us|eu|apac|global|au|ca|jp|us-gov)\\.", var.brms.ai.model))
    error_message = "For amazon-bedrock provider, model must use an inference profile ID with a geographic prefix (e.g., us.amazon.nova-2-lite-v1:0, eu.anthropic.claude-sonnet-4-6-v1:0). See https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles-support.html"
  }
}

# Agent Configuration

variable "agent" {
  description = "GoRules Agent deployment configuration. Set to null to disable. See the wiki for fields."
  type = object({
    image                     = optional(string, "gorules/agent:latest")
    cpu                       = number
    memory                    = number
    port                      = optional(number, 8080)
    min_count                 = optional(number, 1)
    max_count                 = number
    cpu_target                = optional(number, 60)
    health_check_path         = optional(string, "/api/health")
    health_check_grace_period = optional(number, 60)
    domain                    = optional(string)
    certificate_arn           = optional(string)
    route53_zone_id           = optional(string)
    allowed_cidr_blocks       = list(string)
    enable_execute_command    = optional(bool, false)
    deregistration_delay      = optional(number, 30)
    alb_deletion_protection   = optional(bool, true)
    alb_internal              = optional(bool, false)
    alb_http_only             = optional(bool, false)
    alb_idle_timeout          = optional(number, 60)
    env                       = optional(list(object({ name = string, value = string })), [])
    secrets                   = optional(list(object({ name = string, valueFrom = string })), [])
  })
  default = null

  validation {
    condition     = var.agent == null || contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.agent.cpu)
    error_message = "agent.cpu must be a valid Fargate CPU value: 256, 512, 1024, 2048, 4096, 8192, or 16384."
  }

  validation {
    condition     = var.agent == null || var.agent.min_count <= var.agent.max_count
    error_message = "agent.min_count must be less than or equal to agent.max_count."
  }

  validation {
    condition = var.agent == null || var.agent.alb_http_only || var.agent.domain == null || (
      var.agent.route53_zone_id != null || var.agent.certificate_arn != null
    )
    error_message = "When agent.domain is set, provide route53_zone_id or certificate_arn. Alternatively set alb_http_only = true when a trusted edge terminates TLS."
  }

  validation {
    condition     = var.agent == null || !var.agent.alb_http_only || var.agent.alb_internal
    error_message = "agent.alb_http_only requires agent.alb_internal = true. An HTTP-only ALB must be internal and sit behind a TLS-terminating edge such as CloudFront."
  }

  validation {
    condition     = var.agent == null || (var.agent.alb_idle_timeout >= 1 && var.agent.alb_idle_timeout <= 4000)
    error_message = "agent.alb_idle_timeout must be between 1 and 4000 seconds."
  }
}

# Database Configuration (for BRMS)

variable "database" {
  description = "Database connection details passed to BRMS. See the wiki for fields."
  type = object({
    endpoint                   = string
    port                       = optional(number, 5432)
    name                       = string
    username                   = string
    credentials_secret_arn     = optional(string)
    secrets_read_policy_arn    = optional(string)
    ssl_verify                 = optional(bool, true)
    auth                       = optional(string, "secrets")
    rds_iam_connect_policy_arn = optional(string)
  })
  default = null
}

# Storage Configuration

variable "storage" {
  description = "S3 storage details passed to the tasks. See the wiki for fields."
  type = object({
    bucket_name              = string
    bucket_arn               = string
    iam_policy_arn           = optional(string)
    iam_read_only_policy_arn = optional(string)
  })
  default = null
}

variable "brms_external_buckets" {
  description = "External S3 buckets BRMS can write to (cross-account deployments)"
  type = list(object({
    arn  = string
    name = string
  }))
  default = []
}

# Logging Configuration

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention period."
  }
}

variable "secret_recovery_window_in_days" {
  description = "Recovery window before Secrets Manager permanently deletes secrets (0 for immediate delete)"
  type        = number
  default     = 30
}

# Tags

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Monitoring Configuration

variable "alarm_sns_topic_arn" {
  description = "ARN of SNS topic for CloudWatch alarm notifications. If not provided, alarms will not send notifications."
  type        = string
  default     = null
}
