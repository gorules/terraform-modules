output "brms_url" {
  description = "URL for accessing BRMS"
  value       = module.gorules.brms_url
}

output "brms_alb_dns_name" {
  description = "DNS name of the BRMS ALB"
  value       = module.gorules.brms_alb_dns_name
}

output "agent_url" {
  description = "URL for accessing the DEV Agent API"
  value       = module.gorules.agent_url
}

output "agent_alb_dns_name" {
  description = "DNS name of the Agent ALB"
  value       = module.gorules.agent_alb_dns_name
}

output "s3_bucket_name" {
  description = "Name of the DEV S3 bucket"
  value       = module.gorules.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the DEV S3 bucket"
  value       = module.gorules.s3_bucket_arn
}

output "database_endpoint" {
  description = "Aurora cluster endpoint"
  value       = module.gorules.database_endpoint
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.gorules.vpc_id
}

output "brms_task_role_arn" {
  description = "ARN of the BRMS task role (use for cross-account bucket policies)"
  value       = module.gorules.brms_task_role_arn
}

output "brms_external_buckets" {
  description = "External buckets configured for cross-account access"
  value       = module.gorules.brms_external_buckets
}
