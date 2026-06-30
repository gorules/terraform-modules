# Internal ALB example: both ALBs internal in private subnets, not internet-facing.
# create_vpc toggles existing-VPC vs module-built (with NAT for BRMS egress). See the README.

terraform {
  required_version = ">= 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "terraform_data" "preconditions" {
  lifecycle {
    precondition {
      condition     = var.create_vpc || (var.vpc_id != null && length(var.private_subnet_ids) >= 2)
      error_message = "With create_vpc = false, set vpc_id and at least 2 private_subnet_ids in different Availability Zones."
    }
  }
}

module "gorules" {
  source = "../.."

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  tags         = var.tags

  # create_vpc = false uses your VPC; create_vpc = true builds one with a NAT.
  vpc = {
    create             = var.create_vpc
    cidr               = var.vpc_cidr
    nat_gateway_mode   = var.create_vpc ? var.nat_gateway_mode : null
    id                 = var.create_vpc ? null : var.vpc_id
    private_subnet_ids = var.create_vpc ? [] : var.private_subnet_ids
    public_subnet_ids  = var.public_subnet_ids
  }

  storage = {
    create_bucket = true
    auth          = var.storage_auth
    versioning    = true
  }

  database = {
    engine_version           = var.database_engine_version
    instance_count           = var.database_instance_count
    min_capacity             = var.database_min_capacity
    max_capacity             = var.database_max_capacity
    seconds_until_auto_pause = var.database_seconds_until_auto_pause
    deletion_protection      = var.database_deletion_protection
    backup_retention_period  = var.database_backup_retention_period
  }

  # BRMS behind an internal ALB (HTTPS required, so certificate_arn is mandatory).
  brms = {
    license_key_secret_arn  = var.brms_license_key_secret_arn
    image                   = var.brms_image
    cpu                     = var.brms_cpu
    memory                  = var.brms_memory
    min_count               = var.brms_min_count
    max_count               = var.brms_max_count
    domain                  = var.brms_domain
    certificate_arn         = var.brms_certificate_arn
    allowed_cidr_blocks     = var.brms_allowed_cidr_blocks
    alb_internal            = true
    alb_deletion_protection = var.brms_alb_deletion_protection
  }

  # Agent behind an internal ALB (HTTP by default; set domain + cert for HTTPS).
  agent = {
    image                   = var.agent_image
    cpu                     = var.agent_cpu
    memory                  = var.agent_memory
    min_count               = var.agent_min_count
    max_count               = var.agent_max_count
    domain                  = var.agent_domain
    certificate_arn         = var.agent_certificate_arn
    allowed_cidr_blocks     = var.agent_allowed_cidr_blocks
    alb_internal            = true
    alb_deletion_protection = var.agent_alb_deletion_protection
  }
}
