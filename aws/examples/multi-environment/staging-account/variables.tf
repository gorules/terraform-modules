variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "gorules"
}

variable "management_account_id" {
  description = "AWS account ID of the management account (where BRMS runs)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must be a 12-digit AWS account ID."
  }
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
  description = "CPU utilization target for auto-scaling"
  type        = number
  default     = 60
}

variable "agent_domain" {
  description = "Custom domain for Agent (optional, enables HTTPS)"
  type        = string
  default     = null
}

variable "agent_certificate_arn" {
  description = "ACM certificate ARN for Agent HTTPS (required if domain is set)"
  type        = string
  default     = null
}

variable "agent_route53_zone_id" {
  description = "Route53 zone ID for Agent DNS (alternative to certificate_arn)"
  type        = string
  default     = null
}

variable "agent_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the Agent ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
