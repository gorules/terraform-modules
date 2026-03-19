variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "gorules"
}

variable "environment" {
  description = "Environment name for resource naming"
  type        = string
  default     = "dev"
}

variable "brms_license_key_secret_arn" {
  description = "ARN of Secrets Manager secret containing GoRules license key"
  type        = string
}

variable "external_buckets" {
  description = "External S3 buckets for cross-account deployments (Staging, Prod, etc.)"
  type = list(object({
    arn  = string
    name = string
  }))
  default = []
}

variable "brms_image" {
  description = "Docker image for BRMS"
  type        = string
  default     = "gorules/brms:latest"
}

variable "brms_cpu" {
  description = "CPU units for BRMS tasks"
  type        = number
  default     = 512
}

variable "brms_memory" {
  description = "Memory (MB) for BRMS tasks"
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
  default     = 2
}

variable "brms_alb_deletion_protection" {
  description = "Enable deletion protection for BRMS ALB"
  type        = bool
  default     = true
}

variable "brms_cpu_target" {
  description = "CPU utilization target for BRMS auto-scaling"
  type        = number
  default     = 60
}

variable "brms_domain" {
  description = "Custom domain for BRMS (required)"
  type        = string
}

variable "brms_certificate_arn" {
  description = "ACM certificate ARN for BRMS HTTPS"
  type        = string
  default     = null
}

variable "brms_route53_zone_id" {
  description = "Route53 zone ID for BRMS DNS (alternative to certificate_arn)"
  type        = string
  default     = null
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

variable "agent_image" {
  description = "Docker image for the Agent"
  type        = string
  default     = "gorules/agent:latest"
}

variable "agent_cpu" {
  description = "CPU units for Agent tasks"
  type        = number
  default     = 256
}

variable "agent_memory" {
  description = "Memory (MB) for Agent tasks"
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

variable "agent_cpu_target" {
  description = "CPU utilization target for Agent auto-scaling"
  type        = number
  default     = 60
}

variable "agent_domain" {
  description = "Custom domain for Agent (optional, enables HTTPS)"
  type        = string
  default     = null
}

variable "agent_certificate_arn" {
  description = "ACM certificate ARN for Agent HTTPS"
  type        = string
  default     = null
}

variable "agent_route53_zone_id" {
  description = "Route53 zone ID for Agent DNS"
  type        = string
  default     = null
}

variable "database_min_capacity" {
  description = "Minimum ACU capacity for Aurora Serverless"
  type        = number
  default     = 0.5
}

variable "database_max_capacity" {
  description = "Maximum ACU capacity for Aurora Serverless"
  type        = number
  default     = 4
}

variable "database_deletion_protection" {
  description = "Enable deletion protection for Aurora cluster"
  type        = bool
  default     = true
}

variable "brms_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access BRMS ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "agent_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Agent ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
