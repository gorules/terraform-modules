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
  environment  = var.environment
  region       = var.region

  brms = {
    license_key_secret_arn  = var.brms_license_key_secret_arn
    image                   = var.brms_image
    cpu                     = var.brms_cpu
    memory                  = var.brms_memory
    min_count               = var.brms_min_count
    max_count               = var.brms_max_count
    cpu_target              = var.brms_cpu_target
    domain                  = var.brms_domain
    certificate_arn         = var.brms_certificate_arn
    route53_zone_id         = var.brms_route53_zone_id
    allowed_cidr_blocks     = var.brms_allowed_cidr_blocks
    alb_deletion_protection = var.brms_alb_deletion_protection
    external_buckets        = var.external_buckets
    ai = var.brms_ai_enabled ? {
      provider           = var.brms_ai_provider
      model              = var.brms_ai_model
      api_key_secret_arn = var.brms_ai_api_key_secret_arn
      temperature        = var.brms_ai_temperature
      thinking_level     = var.brms_ai_thinking_level
    } : null
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

  database = {
    min_capacity        = var.database_min_capacity
    max_capacity        = var.database_max_capacity
    deletion_protection = var.database_deletion_protection
  }

  storage = {}

  tags = var.tags
}
