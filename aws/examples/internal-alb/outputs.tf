# Service Endpoints

output "brms_url" {
  description = "The URL for accessing BRMS"
  value       = module.gorules.brms_url
}

output "brms_alb_dns_name" {
  description = "The DNS name of the internal BRMS ALB. Point your internal DNS record at this name."
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
  description = "The DNS name of the internal Agent ALB. Point your internal DNS record at this name."
  value       = module.gorules.agent_alb_dns_name
}

output "agent_alb_zone_id" {
  description = "The zone ID of the Agent ALB (use for Route53 alias records)"
  value       = module.gorules.agent_alb_zone_id
}

# Network Resources

output "vpc_id" {
  description = "The ID of the VPC (created or existing)"
  value       = module.gorules.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (created or existing)"
  value       = module.gorules.private_subnet_ids
}

# Storage

output "s3_bucket_name" {
  description = "Name of the S3 bucket for rules storage"
  value       = module.gorules.s3_bucket_name
}

# Database

output "database_endpoint" {
  description = "The Aurora cluster endpoint (writer)"
  value       = module.gorules.database_endpoint
}

# ECS Cluster

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.gorules.ecs_cluster_name
}
