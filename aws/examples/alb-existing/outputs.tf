# Service Endpoints

output "agent_url" {
  description = "The URL for accessing Agent"
  value       = module.gorules.agent_url
}

output "agent_alb_dns_name" {
  description = "The DNS name of the ALB serving Agent (use for DNS configuration)"
  value       = module.gorules.agent_alb_dns_name
}

output "agent_alb_zone_id" {
  description = "The zone ID of the ALB serving Agent (use for Route53 alias records)"
  value       = module.gorules.agent_alb_zone_id
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

output "agent_tasks_security_group_id" {
  description = "The ID of the Agent tasks security group"
  value       = module.gorules.agent_tasks_security_group_id
}
