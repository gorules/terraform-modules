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
  source = "../../../"

  project_name = var.project_name
  environment  = "staging"
  region       = var.region

  storage = {
    cross_account_write_principals = [var.management_account_id]
  }

  agent = {
    image                   = var.agent_image
    cpu                     = var.agent_cpu
    memory                  = var.agent_memory
    min_count               = var.agent_min_count
    max_count               = var.agent_max_count
    cpu_target              = var.agent_cpu_target
    domain                  = var.agent_domain
    certificate_arn         = var.agent_certificate_arn
    route53_zone_id         = var.agent_route53_zone_id
    allowed_cidr_blocks     = var.agent_allowed_cidr_blocks
    alb_deletion_protection = var.agent_alb_deletion_protection
  }

  tags = var.tags
}
