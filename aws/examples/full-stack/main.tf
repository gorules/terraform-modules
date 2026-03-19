# GoRules Full Stack Example
#
# This example deploys the complete GoRules stack:
# - New VPC with public and private subnets
# - Aurora Serverless v2 PostgreSQL database
# - S3 bucket for rules storage
# - BRMS (Business Rules Management System)
# - Agent (Stateless rule evaluation API)

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

  # Storage Configuration - Create new S3 bucket
  storage = {
    create_bucket = true
    auth          = var.storage_auth
    versioning    = true
  }

  # Database Configuration - Aurora Serverless v2
  database = {
    engine_version           = var.database_engine_version
    instance_count           = var.database_instance_count
    min_capacity             = var.database_min_capacity
    max_capacity             = var.database_max_capacity
    seconds_until_auto_pause = var.database_seconds_until_auto_pause
    deletion_protection      = var.database_deletion_protection
    backup_retention_period  = var.database_backup_retention_period
    auth                     = var.database_auth
    iam_username             = var.database_iam_username
  }

  # BRMS Configuration
  brms = {
    license_key_secret_arn  = var.brms_license_key_secret_arn
    image                   = var.brms_image
    cpu                     = var.brms_cpu
    memory                  = var.brms_memory
    min_count               = var.brms_min_count
    max_count               = var.brms_max_count
    domain                  = var.brms_domain
    certificate_arn         = var.brms_certificate_arn
    route53_zone_id         = var.brms_route53_zone_id
    allowed_cidr_blocks     = var.brms_allowed_cidr_blocks
    alb_deletion_protection = var.brms_alb_deletion_protection
    env                     = var.brms_env
    secrets                 = var.brms_secrets
    external_buckets        = var.brms_external_buckets
    ai = var.brms_ai_enabled ? {
      provider           = var.brms_ai_provider
      model              = var.brms_ai_model
      api_key_secret_arn = var.brms_ai_api_key_secret_arn
      temperature        = var.brms_ai_temperature
      thinking_level     = var.brms_ai_thinking_level
    } : null
    secrets_provider = {
      type                = var.brms_secrets_provider_type
      master_key_length   = var.brms_secrets_provider_master_key_length
      create_kms_key      = var.brms_secrets_provider_create_kms_key
      kms_key_arn         = var.brms_secrets_provider_kms_key_arn
      kms_key_alias       = var.brms_secrets_provider_kms_key_alias
      kms_deletion_window = var.brms_secrets_provider_kms_deletion_window
    }
  }

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
