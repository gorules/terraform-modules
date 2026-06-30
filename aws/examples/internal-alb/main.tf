# GoRules Internal ALB Example
#
# Both load balancers use the internal scheme in private subnets. They are not
# reachable from the internet. Use this when policy forbids internet-facing ALBs
# or public-subnet resources, or when the services are reached only from inside
# your network.
#
# BRMS needs outbound internet. It validates its license at
# https://portal.gorules.io, so a VPC with no egress cannot run BRMS. Make sure
# the tasks can reach the internet through your network egress (NAT, a Transit
# Gateway to a shared egress VPC, or a proxy). The Agent is self-contained and
# needs no egress.
#
# Two modes, set by create_vpc:
#   create_vpc = false (default) deploy into a VPC you already have. You pass the
#                      private subnets and provide the egress. The module creates
#                      nothing in a public subnet. This is the path for a
#                      no-public-subnet policy.
#   create_vpc = true  the module builds the VPC. BRMS needs egress, so this mode
#                      adds a NAT gateway. The public subnets it creates host only
#                      the NAT. The ALBs stay internal.

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

  # create_vpc = false uses your VPC and your egress, and creates nothing public.
  # create_vpc = true builds the VPC with a NAT so BRMS can reach its license
  # server. The NAT needs public subnets; the ALBs stay internal.
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

  # BRMS behind an internal ALB. BRMS requires HTTPS, so a certificate ARN is
  # mandatory. allowed_cidr_blocks should list the internal ranges that may reach
  # the ALB, not 0.0.0.0/0.
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

  # Agent behind an internal ALB. Leave agent_domain unset to serve HTTP inside
  # the VPC, or set a domain with a certificate_arn to terminate HTTPS on the ALB.
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
