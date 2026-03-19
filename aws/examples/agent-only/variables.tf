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

# Optional Variables - Tags

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# VPC Configuration

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "nat_gateway_mode" {
  description = "NAT Gateway mode: 'single' for cost savings or 'ha' for high availability"
  type        = string
  default     = "single"
}

variable "enable_vpc_endpoints" {
  description = "Create VPC endpoints for S3, ECR, CloudWatch, Secrets Manager"
  type        = bool
  default     = false
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

variable "cross_account_write_principals" {
  description = "AWS principals (account IDs or IAM role ARNs) allowed cross-account write access to this bucket"
  type        = list(string)
  default     = []
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
  description = "ACM certificate ARN for Agent HTTPS (provide this OR agent_route53_zone_id when domain is set)"
  type        = string
  default     = null
}

variable "agent_route53_zone_id" {
  description = "Route53 hosted zone ID for automatic certificate creation and DNS (provide this OR agent_certificate_arn when domain is set)"
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
