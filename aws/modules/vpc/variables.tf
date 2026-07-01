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
  description = "NAT Gateway deployment mode: 'single' (one NAT gateway, cost savings), 'ha' (one per AZ), or 'none' (no NAT gateway and no EIP; ECS tasks reach AWS through VPC endpoints instead). With 'none' no public subnets are created unless an internet-facing ALB needs them."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "ha", "none"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be 'single', 'ha', or 'none'"
  }
}

variable "create_public_subnets" {
  description = "Whether public subnets (and an internet gateway) are required for an internet-facing ALB. Public subnets are also created automatically when nat_gateway_mode != 'none' to host the NAT gateway. When false and nat_gateway_mode = 'none', the VPC has no public subnets, internet gateway, NAT gateway or EIP."
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Create VPC endpoints (S3 gateway + interface endpoints for ECR, CloudWatch Logs, Secrets Manager, STS) so tasks reach AWS services privately. Endpoints are created automatically when nat_gateway_mode = 'none' because they are then the only egress path."
  type        = bool
  default     = false
}

variable "additional_interface_endpoints" {
  description = "Extra interface VPC endpoint service short-names to create in addition to the base set (ecr.api, ecr.dkr, logs, secretsmanager, sts). For example [\"kms\", \"bedrock-runtime\", \"ssmmessages\"]."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
