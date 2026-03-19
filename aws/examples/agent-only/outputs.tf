# Service Endpoints

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

# Network Resources

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.gorules.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.gorules.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
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

# ECS Cluster

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.gorules.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = module.gorules.ecs_cluster_arn
}
