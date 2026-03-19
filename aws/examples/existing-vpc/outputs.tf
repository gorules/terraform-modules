# Service Endpoints

output "brms_url" {
  description = "The URL for accessing BRMS"
  value       = module.gorules.brms_url
}

output "brms_alb_dns_name" {
  description = "The DNS name of the BRMS ALB (use for DNS configuration)"
  value       = module.gorules.brms_alb_dns_name
}

output "brms_alb_zone_id" {
  description = "The zone ID of the BRMS ALB (use for Route53 alias records)"
  value       = module.gorules.brms_alb_zone_id
}

output "agent_url" {
  description = "The URL for accessing Agent"
  value       = module.gorules.agent_url
}

output "agent_alb_dns_name" {
  description = "The DNS name of the Agent ALB (use for DNS configuration)"
  value       = module.gorules.agent_alb_dns_name
}

output "agent_alb_zone_id" {
  description = "The zone ID of the Agent ALB (use for Route53 alias records)"
  value       = module.gorules.agent_alb_zone_id
}

# Network Resources (existing VPC)

output "vpc_id" {
  description = "The ID of the VPC (existing)"
  value       = module.gorules.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (existing)"
  value       = module.gorules.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (existing)"
  value       = module.gorules.public_subnet_ids
}

# Storage

output "s3_bucket_name" {
  description = "Name of the S3 bucket for rules storage"
  value       = module.gorules.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for rules storage"
  value       = module.gorules.s3_bucket_arn
}

# Database

output "database_endpoint" {
  description = "The Aurora cluster endpoint (writer)"
  value       = module.gorules.database_endpoint
}

output "database_reader_endpoint" {
  description = "The Aurora cluster reader endpoint"
  value       = module.gorules.database_reader_endpoint
}

output "database_port" {
  description = "The database port"
  value       = module.gorules.database_port
}

output "database_name" {
  description = "The name of the database"
  value       = module.gorules.database_name
}

# ECS Cluster

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.gorules.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = module.gorules.ecs_cluster_arn
}

# Secrets

output "database_credentials_secret_arn" {
  description = "The ARN of the database credentials secret"
  value       = module.gorules.database_credentials_secret_arn
}

output "cookie_secret_arn" {
  description = "The ARN of the BRMS cookie secret"
  value       = module.gorules.cookie_secret_arn
}

output "secrets_master_key_secret_arn" {
  description = "The ARN of the BRMS secrets master key (null if using aws-kms provider)"
  value       = module.gorules.secrets_master_key_secret_arn
}

# KMS

output "brms_kms_key_arn" {
  description = "The ARN of the KMS key for BRMS secrets (null if using env provider)"
  value       = module.gorules.brms_kms_key_arn
}
