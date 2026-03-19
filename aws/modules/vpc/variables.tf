variable "name_prefix" {
  description = "Prefix for resource naming (e.g., gorules-prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "cidr must be a valid CIDR block"
  }
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 1 && length(var.availability_zones) <= 6
    error_message = "availability_zones must contain between 1 and 6 AZs"
  }
}

variable "nat_gateway_mode" {
  description = "NAT Gateway deployment mode: 'single' for cost savings or 'ha' for high availability (one per AZ)"
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "ha"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be either 'single' or 'ha'"
  }
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for AWS services (S3, ECR, CloudWatch Logs, Secrets Manager, STS)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
