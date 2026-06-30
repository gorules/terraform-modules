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

# VPC Configuration

variable "create_vpc" {
  description = "Deploy into an existing VPC (false, the default) or let the module build one (true). BRMS needs outbound internet for license validation. With create_vpc = false you provide that egress and the module creates nothing in a public subnet. With create_vpc = true the module adds a NAT for egress, and the public subnets it creates host only the NAT."
  type        = bool
  default     = false
}

variable "nat_gateway_mode" {
  description = "NAT mode for the VPC the module builds. Used only when create_vpc = true. BRMS needs egress, so a NAT is required here. 'single' is one NAT, 'ha' is one per AZ."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "ha"], var.nat_gateway_mode)
    error_message = "This example runs BRMS, which needs outbound internet, so a module-built VPC needs a NAT. Use 'single' or 'ha'. For no public subnets, use an existing VPC (create_vpc = false) with your own egress."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC the module builds. Used only when create_vpc = true."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "ID of an existing VPC. Required when create_vpc = false."
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "Existing private subnet IDs (at least 2, in different AZs). Required when create_vpc = false. The internal ALBs and the ECS tasks run here."
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "Existing public subnet IDs. Not used by internal ALBs, so this defaults to empty. Set it only if you also run an internet-facing ALB."
  type        = list(string)
  default     = []
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
  description = "Container image for BRMS. The default pulls from Docker Hub, which works when the tasks have internet egress. If your egress is restricted to specific hosts, mirror the image to ECR and set the URI here."
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

variable "brms_domain" {
  description = "Custom domain name for BRMS. BRMS requires HTTPS, so this is mandatory. For an internal deployment this is typically an internal hostname that resolves to the ALB private IPs."
  type        = string
}

variable "brms_certificate_arn" {
  description = "ACM certificate ARN for the BRMS domain, in this region. Use AWS Private CA or an imported certificate for a private-only domain. Auto-issue via a Route53 zone is not offered here because ACM DNS validation needs a publicly resolvable zone."
  type        = string
}

variable "brms_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the internal BRMS ALB. Set this to your VPC or corporate ranges rather than 0.0.0.0/0."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "brms_alb_deletion_protection" {
  description = "Enable deletion protection for the BRMS ALB"
  type        = bool
  default     = true
}

# Agent Configuration

variable "agent_image" {
  description = "Container image for Agent. The default pulls from Docker Hub, which works when the tasks have internet egress. If your egress is restricted to specific hosts, mirror the image to ECR and set the URI here."
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
  description = "Custom domain name for Agent (optional). Leave unset to serve HTTP inside the VPC. Set it with agent_certificate_arn to terminate HTTPS on the internal ALB."
  type        = string
  default     = null
}

variable "agent_certificate_arn" {
  description = "ACM certificate ARN for the Agent domain, in this region. Required only when agent_domain is set."
  type        = string
  default     = null
}

variable "agent_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the internal Agent ALB. Set this to your VPC or corporate ranges rather than 0.0.0.0/0."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "agent_alb_deletion_protection" {
  description = "Enable deletion protection for the Agent ALB"
  type        = bool
  default     = true
}
