# GoRules Existing ALB Example
#
# This example deploys an additional Agent behind an existing ALB:
# - Uses an existing VPC (shared with the ALB)
# - Attaches to an existing ALB listener via a host-based listener rule
# - S3 bucket for rules storage (or use existing bucket)
# - Agent (Stateless rule evaluation API)
#
# Use this pattern when:
# - You run multiple Agent deployments (per tenant, team, or business unit)
#   and want them to share one VPC, one ALB, and one ECS-hosting account
# - Another GoRules invocation (or your own Terraform) already owns the ALB
#   and exposes its listener ARN and security group ID

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

  # VPC Configuration - Use the VPC the existing ALB lives in
  vpc = {
    create             = false
    id                 = var.vpc_id
    private_subnet_ids = var.private_subnet_ids
  }

  # Storage Configuration
  storage = {
    create_bucket        = var.create_bucket
    existing_bucket_arn  = var.existing_bucket_arn
    existing_bucket_name = var.existing_bucket_name
    auth                 = var.storage_auth
    versioning           = true
  }

  # Database - Not needed for Agent-only deployment
  database = null

  # BRMS - Not needed for Agent-only deployment
  brms = null

  # Agent Configuration - Attach to the existing ALB
  agent = {
    image           = var.agent_image
    cpu             = var.agent_cpu
    memory          = var.agent_memory
    min_count       = var.agent_min_count
    max_count       = var.agent_max_count
    domain          = var.agent_domain
    certificate_arn = var.agent_certificate_arn
    route53_zone_id = var.agent_route53_zone_id

    alb = {
      create            = false
      listener_arn      = var.alb_listener_arn
      security_group_id = var.alb_security_group_id
      priority          = var.alb_rule_priority
    }

    env     = var.agent_env
    secrets = var.agent_secrets
  }
}
