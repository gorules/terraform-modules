output "s3_bucket_name" {
  description = "Name of the S3 bucket (provide to management account)"
  value       = module.gorules.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket (provide to management account)"
  value       = module.gorules.s3_bucket_arn
}

output "agent_url" {
  description = "URL for accessing the Agent API"
  value       = module.gorules.agent_url
}

output "agent_alb_dns_name" {
  description = "DNS name of the Agent ALB"
  value       = module.gorules.agent_alb_dns_name
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.gorules.vpc_id
}
