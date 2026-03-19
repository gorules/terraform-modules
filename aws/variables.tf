# Required Variables

variable "project_name" {
  description = "Project name used for resource naming. Must be lowercase alphanumeric with hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name)) && length(var.project_name) >= 2 && length(var.project_name) <= 32
    error_message = "Project name must be 2-32 characters, lowercase alphanumeric with hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod). Used for resource naming and tagging."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.environment)) && length(var.environment) >= 2 && length(var.environment) <= 16
    error_message = "Environment must be 2-16 characters, lowercase alphanumeric with hyphens, starting with a letter."
  }
}

variable "region" {
  description = "AWS region for resource deployment."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

# Optional Variables

variable "tags" {
  description = "Additional tags to apply to all resources. Merged with default tags (Project, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}

# Monitoring Configuration

variable "alarm_sns_topic_arn" {
  description = "ARN of SNS topic for CloudWatch alarm notifications. If not provided, alarms will not send notifications."
  type        = string
  default     = null
}

# VPC Configuration

variable "vpc" {
  description = <<-EOT
    VPC configuration. Set create=true to create a new VPC, or create=false with existing VPC details.

    Options:
    - create: Whether to create a new VPC (default: true)
    - cidr: VPC CIDR block for new VPC (default: "10.0.0.0/16")
    - availability_zones: List of AZs to use. Empty list uses first 2 available AZs.
    - nat_gateway_mode: "single" for cost savings or "ha" for high availability (default: "single")
    - enable_vpc_endpoints: Create VPC endpoints for S3, ECR, CloudWatch, Secrets Manager (default: false)
    - id: Existing VPC ID (required if create=false)
    - private_subnet_ids: Existing private subnet IDs (required if create=false)
    - public_subnet_ids: Existing public subnet IDs (required if create=false)
  EOT
  type = object({
    create               = optional(bool, true)
    cidr                 = optional(string, "10.0.0.0/16")
    availability_zones   = optional(list(string), [])
    nat_gateway_mode     = optional(string, "single")
    enable_vpc_endpoints = optional(bool, false)
    id                   = optional(string)
    private_subnet_ids   = optional(list(string), [])
    public_subnet_ids    = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = var.vpc == null || var.vpc.nat_gateway_mode == null || contains(["single", "ha"], var.vpc.nat_gateway_mode)
    error_message = "nat_gateway_mode must be 'single' or 'ha'."
  }

  validation {
    condition = var.vpc == null || var.vpc.create == true || (
      var.vpc.id != null &&
      length(var.vpc.private_subnet_ids) > 0 &&
      length(var.vpc.public_subnet_ids) > 0
    )
    error_message = "When create=false, id, private_subnet_ids, and public_subnet_ids are required."
  }

  validation {
    condition     = var.vpc == null || var.vpc.cidr == null || can(cidrhost(var.vpc.cidr, 0))
    error_message = "cidr must be a valid CIDR block."
  }
}

# Storage Configuration (S3)

variable "storage" {
  description = <<-EOT
    S3 storage configuration for GoRules rules. Set to null to disable storage creation.

    Options:
    - create_bucket: Create a new S3 bucket (default: true)
    - existing_bucket_arn: ARN of existing bucket (required if create_bucket=false)
    - existing_bucket_name: Name of existing bucket (required if create_bucket=false)
    - auth: Authentication method - "iam" (recommended) or "secrets" (default: "iam")
    - versioning: Enable S3 versioning (default: true)
    - cross_account_write_principals: IAM role ARNs for cross-account write access (default: [])
      RECOMMENDED: Use specific IAM role ARNs for least-privilege access.
      WARNING: Account IDs grant access to ALL principals in that account.
  EOT
  type = object({
    create_bucket                  = optional(bool, true)
    existing_bucket_arn            = optional(string)
    existing_bucket_name           = optional(string)
    auth                           = optional(string, "iam")
    versioning                     = optional(bool, true)
    cross_account_write_principals = optional(list(string), [])
  })
  default = null

  validation {
    condition     = var.storage == null || contains(["iam", "secrets"], var.storage.auth)
    error_message = "storage.auth must be 'iam' or 'secrets'."
  }

  validation {
    condition = var.storage == null || var.storage.create_bucket == true || (
      var.storage.existing_bucket_arn != null && var.storage.existing_bucket_name != null
    )
    error_message = "When create_bucket=false, both existing_bucket_arn and existing_bucket_name are required."
  }

  validation {
    condition     = var.storage == null || var.storage.existing_bucket_arn == null || can(regex("^arn:aws:s3:::", var.storage.existing_bucket_arn))
    error_message = "existing_bucket_arn must be a valid S3 bucket ARN."
  }

  validation {
    condition = var.storage == null || alltrue([
      for p in coalesce(var.storage.cross_account_write_principals, []) :
      can(regex("^[0-9]{12}$", p)) || can(regex("^arn:aws(-us-gov|-cn)?:iam::[0-9]{12}:role/.+$", p))
    ])
    error_message = "Each cross_account_write_principals entry must be a 12-digit AWS account ID or IAM role ARN."
  }
}

# Database Configuration (Aurora Serverless v2)

variable "database" {
  description = <<-EOT
    Aurora Serverless v2 PostgreSQL configuration. Set to null to disable database creation.
    Required when deploying BRMS component.

    Options:
    - engine_version: PostgreSQL engine version (default: "17.4")
    - instance_count: Number of Aurora instances (default: 1)
    - min_capacity: Minimum ACU capacity (0-256). Set to 0 to enable auto-pause.
    - max_capacity: Maximum ACU capacity (0.5-256)
    - seconds_until_auto_pause: Seconds before auto-pause when idle (300-86400, null to disable). Requires min_capacity = 0.
    - master_username: Master database username (default: "gorules_admin")
    - deletion_protection: Enable deletion protection (default: true)
    - backup_retention_period: Backup retention period in days (default: 7)
    - apply_immediately: Apply changes immediately vs during maintenance window (default: false)
    - auth: Authentication method - "secrets" (password via Secrets Manager) or "iam" (IAM database auth) (default: "secrets")
    - iam_username: Username for IAM database authentication (default: "gorules_user", only used when auth="iam")
  EOT
  type = object({
    engine_version           = optional(string, "17.4")
    instance_count           = optional(number, 1)
    min_capacity             = number
    max_capacity             = number
    seconds_until_auto_pause = optional(number)
    master_username          = optional(string, "gorules_admin")
    deletion_protection      = optional(bool, true)
    backup_retention_period  = optional(number, 7)
    apply_immediately        = optional(bool, false)
    auth                     = optional(string, "secrets")
    iam_username             = optional(string, "gorules_user")
  })
  default = null

  validation {
    condition     = var.database == null || (var.database.min_capacity >= 0 && var.database.min_capacity <= 256)
    error_message = "database.min_capacity must be between 0 and 256 ACUs."
  }

  validation {
    condition     = var.database == null || (var.database.max_capacity >= 0.5 && var.database.max_capacity <= 256)
    error_message = "database.max_capacity must be between 0.5 and 256 ACUs."
  }

  validation {
    condition     = var.database == null || var.database.min_capacity <= var.database.max_capacity
    error_message = "database.min_capacity must be less than or equal to max_capacity."
  }

  validation {
    condition     = var.database == null || (var.database.backup_retention_period >= 1 && var.database.backup_retention_period <= 35)
    error_message = "database.backup_retention_period must be between 1 and 35 days."
  }

  validation {
    condition     = var.database == null || var.database.instance_count >= 1
    error_message = "database.instance_count must be at least 1."
  }

  validation {
    condition     = var.database == null || var.database.seconds_until_auto_pause == null || (var.database.seconds_until_auto_pause >= 300 && var.database.seconds_until_auto_pause <= 86400)
    error_message = "database.seconds_until_auto_pause must be between 300 and 86400 seconds, or null to disable."
  }

  validation {
    condition     = var.database == null || var.database.seconds_until_auto_pause == null || var.database.min_capacity == 0
    error_message = "database.seconds_until_auto_pause requires min_capacity = 0. Auto-pause only works when the cluster can scale to 0 ACUs."
  }

  validation {
    condition     = var.database == null || contains(["secrets", "iam"], var.database.auth)
    error_message = "database.auth must be 'secrets' or 'iam'."
  }
}

# BRMS Configuration

variable "brms" {
  description = <<-EOT
    BRMS (Business Rules Management System) configuration. Set to null to disable BRMS deployment.
    Requires database and storage components. BRMS requires HTTPS - you must provide either
    route53_zone_id (auto-create certificate) or certificate_arn (existing certificate).

    Options:
    - license_key_secret_arn: ARN of Secrets Manager secret containing GoRules license key (REQUIRED)
    - image: Docker image for BRMS (default: "gorules/brms:latest")
    - cpu: Fargate CPU units (256, 512, 1024, 2048, 4096, 8192, 16384)
    - memory: Fargate memory in MB (must be valid for CPU)
    - port: Container port (default: 80)
    - min_count: Minimum number of tasks (default: 1)
    - max_count: Maximum number of tasks
    - cpu_target: CPU utilization target for auto-scaling (default: 60)
    - health_check_path: Health check endpoint (default: "/api/health")
    - domain: Custom domain name (REQUIRED for HTTPS)
    - certificate_arn: ACM certificate ARN for HTTPS (provide this OR route53_zone_id)
    - route53_zone_id: Route53 hosted zone ID for automatic certificate creation and DNS (provide this OR certificate_arn)
    - allowed_cidr_blocks: CIDR blocks allowed to access ALB
    - alb_deletion_protection: Enable ALB deletion protection (default: true)
    - env: Additional environment variables
    - secrets: Additional secrets from Secrets Manager
    - external_buckets: List of external S3 buckets for cross-account deployments (default: [])
    - ai: AI/LLM configuration for BRMS AI assistant (default: null, AI disabled)
      - provider: LLM provider (openai, anthropic, google, amazon-bedrock, azure-openai)
      - model: Model name or inference profile ID (e.g., us.anthropic.claude-sonnet-4-6-v1:0, us.amazon.nova-2-lite-v1:0). For amazon-bedrock, newer models require inference profile IDs with a geographic prefix (us., eu., global., etc.).
      - api_key_secret_arn: Secrets Manager ARN for API key (not needed for amazon-bedrock)
      - temperature: Sampling temperature 0-2 (default: 0.4)
      - context_window: Context window in tokens (default: provider default)
      - max_output_tokens: Max response tokens (default: 32000)
      - thinking_level: high, medium, low (default: medium)
      - azure_resource_name: Azure resource name (required for azure-openai)
  EOT
  type = object({
    license_key_secret_arn  = string
    image                   = optional(string, "gorules/brms:latest")
    cpu                     = number
    memory                  = number
    port                    = optional(number, 80)
    min_count               = optional(number, 1)
    max_count               = number
    cpu_target              = optional(number, 60)
    health_check_path       = optional(string, "/api/health")
    domain                  = string
    certificate_arn         = optional(string)
    route53_zone_id         = optional(string)
    allowed_cidr_blocks     = list(string)
    alb_deletion_protection = optional(bool, true)
    env                     = optional(list(object({ name = string, value = string })), [])
    secrets                 = optional(list(object({ name = string, valueFrom = string })), [])
    secrets_provider = optional(object({
      type                = optional(string, "env")
      master_key_length   = optional(number, 64)
      create_kms_key      = optional(bool, true)
      kms_key_arn         = optional(string)
      kms_key_alias       = optional(string)
      kms_deletion_window = optional(number, 30)
    }), { type = "env" })
    external_buckets = optional(list(object({
      arn  = string
      name = string
    })), [])
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
    condition     = var.brms == null || var.brms.min_count <= var.brms.max_count
    error_message = "brms.min_count must be less than or equal to max_count."
  }

  validation {
    condition     = var.brms == null || var.brms.min_count >= 0
    error_message = "brms.min_count must be non-negative."
  }

  validation {
    condition     = var.brms == null || (var.brms.cpu_target >= 1 && var.brms.cpu_target <= 100)
    error_message = "brms.cpu_target must be between 1 and 100."
  }

  validation {
    condition     = var.brms == null || length(var.brms.allowed_cidr_blocks) > 0
    error_message = "brms.allowed_cidr_blocks must contain at least one CIDR block."
  }

  validation {
    condition     = var.brms == null || can(regex("^arn:aws:secretsmanager:", var.brms.license_key_secret_arn))
    error_message = "brms.license_key_secret_arn must be a valid Secrets Manager ARN."
  }

  validation {
    condition     = var.brms == null || contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.brms.cpu)
    error_message = "brms.cpu must be one of: 256, 512, 1024, 2048, 4096, 8192, 16384."
  }

  validation {
    condition = var.brms == null || (
      (var.brms.cpu == 256 && contains([512, 1024, 2048], var.brms.memory)) ||
      (var.brms.cpu == 512 && contains([1024, 2048, 3072, 4096], var.brms.memory)) ||
      (var.brms.cpu == 1024 && contains([2048, 3072, 4096, 5120, 6144, 7168, 8192], var.brms.memory)) ||
      (var.brms.cpu == 2048 && var.brms.memory >= 4096 && var.brms.memory <= 16384 && var.brms.memory % 1024 == 0) ||
      (var.brms.cpu == 4096 && var.brms.memory >= 8192 && var.brms.memory <= 30720 && var.brms.memory % 1024 == 0) ||
      (var.brms.cpu == 8192 && var.brms.memory >= 16384 && var.brms.memory <= 61440 && var.brms.memory % 4096 == 0) ||
      (var.brms.cpu == 16384 && var.brms.memory >= 32768 && var.brms.memory <= 122880 && var.brms.memory % 8192 == 0)
    )
    error_message = "brms.memory is not valid for the specified CPU. See Fargate task size documentation."
  }

  validation {
    condition = var.brms == null || (
      var.brms.route53_zone_id != null || var.brms.certificate_arn != null
    )
    error_message = "BRMS requires HTTPS. Provide either route53_zone_id (auto-create certificate) or certificate_arn (existing certificate)."
  }

  validation {
    condition     = var.brms == null || contains(["env", "aws-kms"], var.brms.secrets_provider.type)
    error_message = "brms.secrets_provider.type must be 'env' or 'aws-kms'."
  }

  validation {
    condition     = var.brms == null || var.brms.secrets_provider.type != "env" || var.brms.secrets_provider.master_key_length >= 32
    error_message = "brms.secrets_provider.master_key_length must be at least 32 characters."
  }

  validation {
    condition     = var.brms == null || var.brms.secrets_provider.type != "aws-kms" || var.brms.secrets_provider.create_kms_key == true || var.brms.secrets_provider.kms_key_arn != null
    error_message = "brms.secrets_provider.kms_key_arn is required when type='aws-kms' and create_kms_key=false."
  }

  validation {
    condition     = var.brms == null || var.brms.secrets_provider.kms_key_arn == null || can(regex("^arn:aws:kms:", var.brms.secrets_provider.kms_key_arn))
    error_message = "brms.secrets_provider.kms_key_arn must be a valid KMS key ARN."
  }

  validation {
    condition     = var.brms == null || (var.brms.secrets_provider.kms_deletion_window >= 7 && var.brms.secrets_provider.kms_deletion_window <= 30)
    error_message = "brms.secrets_provider.kms_deletion_window must be between 7 and 30 days."
  }

  validation {
    condition = var.brms == null || alltrue([
      for b in coalesce(var.brms.external_buckets, []) :
      can(regex("^arn:aws(-us-gov|-cn)?:s3:::.+$", b.arn))
    ])
    error_message = "Each external_buckets entry must have a valid S3 bucket ARN."
  }

  validation {
    condition = var.brms == null || alltrue([
      for b in coalesce(var.brms.external_buckets, []) :
      b.name == regex("^arn:aws(-us-gov|-cn)?:s3:::(.+)$", b.arn)[1]
    ])
    error_message = "Each external_buckets entry name must match the bucket name in the ARN."
  }

  validation {
    condition     = var.brms == null || var.brms.ai == null || contains(["openai", "anthropic", "google", "amazon-bedrock", "azure-openai"], var.brms.ai.provider)
    error_message = "brms.ai.provider must be one of: openai, anthropic, google, amazon-bedrock, azure-openai."
  }

  validation {
    condition     = var.brms == null || var.brms.ai == null || var.brms.ai.provider == "amazon-bedrock" || var.brms.ai.api_key_secret_arn != null
    error_message = "brms.ai.api_key_secret_arn is required when ai.provider is not amazon-bedrock."
  }

  validation {
    condition     = var.brms == null || var.brms.ai == null || var.brms.ai.api_key_secret_arn == null || can(regex("^arn:aws:secretsmanager:", var.brms.ai.api_key_secret_arn))
    error_message = "brms.ai.api_key_secret_arn must be a valid Secrets Manager ARN."
  }

  validation {
    condition     = var.brms == null || var.brms.ai == null || var.brms.ai.provider != "azure-openai" || var.brms.ai.azure_resource_name != null
    error_message = "brms.ai.azure_resource_name is required when ai.provider is azure-openai."
  }

  validation {
    condition     = var.brms == null || var.brms.ai == null || (var.brms.ai.temperature >= 0 && var.brms.ai.temperature <= 2)
    error_message = "brms.ai.temperature must be between 0 and 2."
  }

  validation {
    condition     = var.brms == null || var.brms.ai == null || contains(["high", "medium"], var.brms.ai.thinking_level)
    error_message = "brms.ai.thinking_level must be one of: high, medium."
  }

  validation {
    condition     = var.brms == null || var.brms.ai == null || var.brms.ai.max_output_tokens > 0
    error_message = "brms.ai.max_output_tokens must be greater than 0."
  }

  validation {
    condition     = var.brms == null || var.brms.ai == null || var.brms.ai.context_window == null || var.brms.ai.context_window > 0
    error_message = "brms.ai.context_window must be greater than 0 when set."
  }

  validation {
    condition     = var.brms == null || var.brms.ai == null || var.brms.ai.provider != "amazon-bedrock" || can(regex("^(us|eu|apac|global|au|ca|jp|us-gov)\\.", var.brms.ai.model))
    error_message = "For amazon-bedrock provider, model must use an inference profile ID with a geographic prefix (e.g., us.amazon.nova-2-lite-v1:0, eu.anthropic.claude-sonnet-4-6-v1:0). See https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles-support.html"
  }
}

# Agent Configuration

variable "agent" {
  description = <<-EOT
    GoRules Agent configuration. Set to null to disable Agent deployment.
    Requires storage component. Agent is stateless and pulls rules from S3.
    Agent can run HTTP-only (no domain) or HTTPS (with domain + certificate).

    Options:
    - image: Docker image for Agent (default: "gorules/agent:latest")
    - cpu: Fargate CPU units (256, 512, 1024, 2048, 4096, 8192, 16384)
    - memory: Fargate memory in MB (must be valid for CPU)
    - port: Container port (default: 8080)
    - min_count: Minimum number of tasks (default: 1)
    - max_count: Maximum number of tasks
    - cpu_target: CPU utilization target for auto-scaling (default: 60)
    - health_check_path: Health check endpoint (default: "/api/health")
    - domain: Custom domain name (optional, enables HTTPS when provided with certificate)
    - certificate_arn: ACM certificate ARN for HTTPS (provide this OR route53_zone_id when domain is set)
    - route53_zone_id: Route53 hosted zone ID for automatic certificate creation and DNS (provide this OR certificate_arn when domain is set)
    - allowed_cidr_blocks: CIDR blocks allowed to access ALB
    - alb_deletion_protection: Enable ALB deletion protection (default: true)
    - env: Additional environment variables
    - secrets: Additional secrets from Secrets Manager
  EOT
  type = object({
    image                   = optional(string, "gorules/agent:latest")
    cpu                     = number
    memory                  = number
    port                    = optional(number, 8080)
    min_count               = optional(number, 1)
    max_count               = number
    cpu_target              = optional(number, 60)
    health_check_path       = optional(string, "/api/health")
    domain                  = optional(string)
    certificate_arn         = optional(string)
    route53_zone_id         = optional(string)
    allowed_cidr_blocks     = list(string)
    alb_deletion_protection = optional(bool, true)
    env                     = optional(list(object({ name = string, value = string })), [])
    secrets                 = optional(list(object({ name = string, valueFrom = string })), [])
  })
  default = null

  validation {
    condition     = var.agent == null || var.agent.min_count <= var.agent.max_count
    error_message = "agent.min_count must be less than or equal to max_count."
  }

  validation {
    condition     = var.agent == null || var.agent.min_count >= 0
    error_message = "agent.min_count must be non-negative."
  }

  validation {
    condition     = var.agent == null || (var.agent.cpu_target >= 1 && var.agent.cpu_target <= 100)
    error_message = "agent.cpu_target must be between 1 and 100."
  }

  validation {
    condition     = var.agent == null || length(var.agent.allowed_cidr_blocks) > 0
    error_message = "agent.allowed_cidr_blocks must contain at least one CIDR block."
  }

  validation {
    condition     = var.agent == null || contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.agent.cpu)
    error_message = "agent.cpu must be one of: 256, 512, 1024, 2048, 4096, 8192, 16384."
  }

  validation {
    condition = var.agent == null || (
      (var.agent.cpu == 256 && contains([512, 1024, 2048], var.agent.memory)) ||
      (var.agent.cpu == 512 && contains([1024, 2048, 3072, 4096], var.agent.memory)) ||
      (var.agent.cpu == 1024 && contains([2048, 3072, 4096, 5120, 6144, 7168, 8192], var.agent.memory)) ||
      (var.agent.cpu == 2048 && var.agent.memory >= 4096 && var.agent.memory <= 16384 && var.agent.memory % 1024 == 0) ||
      (var.agent.cpu == 4096 && var.agent.memory >= 8192 && var.agent.memory <= 30720 && var.agent.memory % 1024 == 0) ||
      (var.agent.cpu == 8192 && var.agent.memory >= 16384 && var.agent.memory <= 61440 && var.agent.memory % 4096 == 0) ||
      (var.agent.cpu == 16384 && var.agent.memory >= 32768 && var.agent.memory <= 122880 && var.agent.memory % 8192 == 0)
    )
    error_message = "agent.memory is not valid for the specified CPU. See Fargate task size documentation."
  }

  validation {
    condition = var.agent == null || var.agent.domain == null || (
      var.agent.route53_zone_id != null || var.agent.certificate_arn != null
    )
    error_message = "When agent.domain is set, provide either route53_zone_id (auto-create certificate) or certificate_arn (existing certificate)."
  }
}
