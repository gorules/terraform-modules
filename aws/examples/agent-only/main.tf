# GoRules Agent-Only Example
#
# This example deploys only the GoRules Agent with S3 storage:
# - New VPC with public and private subnets
# - S3 bucket for rules storage (or use existing bucket)
# - Agent (Stateless rule evaluation API)
#
# Use this pattern when:
# - You manage rules in a separate BRMS instance
# - You want a lightweight, stateless deployment for production workloads
# - You need to scale rule evaluation independently

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

module "gorules" {
  source = "../.."

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  tags         = var.tags

  # VPC Configuration - Create new VPC
  vpc = {
    create               = true
    cidr                 = var.vpc_cidr
    nat_gateway_mode     = var.nat_gateway_mode
    enable_vpc_endpoints = var.enable_vpc_endpoints
  }

  # Storage Configuration
  storage = {
    create_bucket                  = var.create_bucket
    existing_bucket_arn            = var.existing_bucket_arn
    existing_bucket_name           = var.existing_bucket_name
    auth                           = var.storage_auth
    versioning                     = true
    cross_account_write_principals = var.cross_account_write_principals
  }

  # Database - Not needed for Agent-only deployment
  database = null

  # BRMS - Not needed for Agent-only deployment
  brms = null

  # Agent Configuration
  agent = {
    image                   = var.agent_image
    cpu                     = var.agent_cpu
    memory                  = var.agent_memory
    min_count               = var.agent_min_count
    max_count               = var.agent_max_count
    domain                  = var.agent_domain
    certificate_arn         = var.agent_certificate_arn
    route53_zone_id         = var.agent_route53_zone_id
    allowed_cidr_blocks     = var.agent_allowed_cidr_blocks
    alb_deletion_protection = var.agent_alb_deletion_protection
    env                     = var.agent_env
    secrets                 = var.agent_secrets
  }
}
