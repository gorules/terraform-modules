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

variable "vpc_id" {
  description = "ID of the existing VPC the ALB lives in"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_listener_arn" {
  description = "ARN of the existing ALB listener to attach the Agent to (HTTPS listener of another GoRules invocation, or your own)"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the existing ALB"
  type        = string
}

# Optional Variables - Tags

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Storage Configuration

variable "create_bucket" {
  description = "Create a new S3 bucket (false to use existing bucket)"
  type        = bool
  default     = true
}

variable "existing_bucket_arn" {
  description = "ARN of existing S3 bucket (required if create_bucket=false)"
  type        = string
  default     = null
}

variable "existing_bucket_name" {
  description = "Name of existing S3 bucket (required if create_bucket=false)"
  type        = string
  default     = null
}

variable "storage_auth" {
  description = "S3 authentication method: 'iam' (recommended) or 'secrets'"
  type        = string
  default     = "iam"
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

variable "agent_domain" {
  description = "Domain name for this Agent deployment (used as the host-header routing condition and for the ACM certificate)"
  type        = string
}

variable "agent_certificate_arn" {
  description = "ACM certificate ARN for the Agent domain (provide this OR agent_route53_zone_id)"
  type        = string
  default     = null
}

variable "agent_route53_zone_id" {
  description = "Route53 hosted zone ID for automatic certificate creation and DNS (provide this OR agent_certificate_arn)"
  type        = string
  default     = null
}

variable "alb_rule_priority" {
  description = "Priority for the listener rule (leave null to auto-assign the next available)"
  type        = number
  default     = null
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
