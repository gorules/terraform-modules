# Service Endpoint Outputs

output "brms_url" {
  description = "The URL for accessing BRMS (custom domain with HTTPS, or ALB DNS with HTTP)"
  value       = local.brms_url
}

output "brms_alb_dns_name" {
  description = "The DNS name of the BRMS Application Load Balancer (use for DNS configuration)"
  value       = local.create_brms && local.create_ecs ? module.ecs[0].brms_alb_dns_name : null
}

output "brms_alb_zone_id" {
  description = "The zone ID of the BRMS ALB (use for Route53 alias records)"
  value       = local.create_brms && local.create_ecs ? module.ecs[0].brms_alb_zone_id : null
}

output "agent_url" {
  description = "The URL for accessing Agent (custom domain with HTTPS, or ALB DNS with HTTP)"
  value       = local.agent_url
}

output "agent_alb_dns_name" {
  description = "The DNS name of the Agent Application Load Balancer (use for DNS configuration)"
  value       = local.create_agent && local.create_ecs ? module.ecs[0].agent_alb_dns_name : null
}

output "agent_alb_zone_id" {
  description = "The zone ID of the Agent ALB (use for Route53 alias records)"
  value       = local.create_agent && local.create_ecs ? module.ecs[0].agent_alb_zone_id : null
}

# Network Resource Outputs

output "vpc_id" {
  description = "The ID of the VPC (created or existing)"
  value       = local.create_vpc || var.vpc != null ? local.vpc_id : null
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (created or existing)"
  value       = local.create_vpc || var.vpc != null ? local.private_subnet_ids : []
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (created or existing)"
  value       = local.create_vpc || var.vpc != null ? local.public_subnet_ids : []
}

# Storage Outputs

output "s3_bucket_name" {
  description = "Name of the S3 bucket for GoRules rules storage"
  value       = local.create_storage ? local.bucket_name : null
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for GoRules rules storage"
  value       = local.create_storage ? local.bucket_arn : null
}

# Database Outputs

output "database_endpoint" {
  description = "The Aurora cluster endpoint (writer)"
  value       = local.create_database ? module.database[0].endpoint : null
}

output "database_reader_endpoint" {
  description = "The Aurora cluster reader endpoint"
  value       = local.create_database ? module.database[0].reader_endpoint : null
}

output "database_port" {
  description = "The database port"
  value       = local.create_database ? module.database[0].port : null
}

output "database_name" {
  description = "The name of the database"
  value       = local.create_database ? module.database[0].database_name : null
}

# ECS Cluster Outputs

output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = local.create_ecs ? module.ecs[0].cluster_id : null
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = local.create_ecs ? module.ecs[0].cluster_arn : null
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = local.create_ecs ? module.ecs[0].cluster_name : null
}

# Security Group Outputs

output "brms_tasks_security_group_id" {
  description = "The ID of the BRMS tasks security group"
  value       = local.create_brms && local.create_ecs ? module.ecs[0].brms_tasks_security_group_id : null
}

output "agent_tasks_security_group_id" {
  description = "The ID of the Agent tasks security group"
  value       = local.create_agent && local.create_ecs ? module.ecs[0].agent_tasks_security_group_id : null
}

output "database_security_group_id" {
  description = "The ID of the Aurora database security group"
  value       = local.create_database ? module.database[0].security_group_id : null
}

# IAM Role Outputs

output "ecs_task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  value       = local.create_ecs ? module.ecs[0].ecs_task_execution_role_arn : null
}

output "brms_task_role_arn" {
  description = "The ARN of the BRMS task role"
  value       = local.create_brms && local.create_ecs ? module.ecs[0].brms_task_role_arn : null
}

output "agent_task_role_arn" {
  description = "The ARN of the Agent task role"
  value       = local.create_agent && local.create_ecs ? module.ecs[0].agent_task_role_arn : null
}

# Secrets Manager Outputs

output "database_credentials_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing database credentials"
  value       = local.create_database ? module.database[0].credentials_secret_arn : null
}

output "storage_credentials_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing S3 credentials (null if auth=iam)"
  value       = local.create_bucket ? module.storage[0].credentials_secret_arn : null
}

output "cookie_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the BRMS cookie secret"
  value       = local.create_brms && local.create_ecs ? module.ecs[0].cookie_secret_arn : null
}

output "secrets_master_key_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the BRMS secrets master key (null if using aws-kms provider)"
  value       = local.create_brms && local.create_ecs ? module.ecs[0].secrets_master_key_secret_arn : null
}

# KMS Outputs

output "brms_kms_key_arn" {
  description = "The ARN of the KMS key created for BRMS secrets encryption (null if using env provider or existing key)"
  value       = local.create_brms && local.create_ecs ? module.ecs[0].brms_kms_key_arn : null
}

output "brms_kms_key_id" {
  description = "The ID of the KMS key used for BRMS secrets encryption (null if using env provider)"
  value       = local.create_brms && local.create_ecs ? module.ecs[0].brms_kms_key_id : null
}

# Certificate Outputs

output "brms_certificate_arn" {
  description = "The ARN of the BRMS ACM certificate (created or provided)"
  value       = local.create_brms && local.create_ecs ? module.ecs[0].brms_certificate_arn : null
}

output "agent_certificate_arn" {
  description = "The ARN of the Agent ACM certificate (created or provided)"
  value       = local.create_agent && local.create_ecs ? module.ecs[0].agent_certificate_arn : null
}

# Cross-Account Outputs

output "brms_external_buckets" {
  description = "External S3 buckets BRMS can write to (cross-account)"
  value       = local.create_brms && var.brms != null ? coalesce(var.brms.external_buckets, []) : []
}
