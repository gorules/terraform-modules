# ECS Cluster Outputs

output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

# BRMS Outputs

output "brms_url" {
  description = "The URL for accessing BRMS (custom domain with HTTPS, or ALB DNS with HTTP)"
  value       = local.create_brms ? local.brms_app_url : null
}

output "brms_alb_dns_name" {
  description = "The DNS name of the BRMS Application Load Balancer"
  value       = local.create_brms ? aws_lb.brms[0].dns_name : null
}

output "brms_alb_zone_id" {
  description = "The zone ID of the BRMS ALB (for Route53 alias records)"
  value       = local.create_brms ? aws_lb.brms[0].zone_id : null
}

output "brms_alb_arn" {
  description = "The ARN of the BRMS Application Load Balancer"
  value       = local.create_brms ? aws_lb.brms[0].arn : null
}

output "brms_target_group_arn" {
  description = "The ARN of the BRMS target group"
  value       = local.create_brms ? aws_lb_target_group.brms[0].arn : null
}

output "brms_service_name" {
  description = "The name of the BRMS ECS service"
  value       = local.create_brms ? aws_ecs_service.brms[0].name : null
}

output "brms_task_definition_arn" {
  description = "The ARN of the BRMS task definition"
  value       = local.create_brms ? aws_ecs_task_definition.brms[0].arn : null
}

output "brms_log_group_name" {
  description = "The name of the BRMS CloudWatch log group"
  value       = local.create_brms ? aws_cloudwatch_log_group.brms[0].name : null
}

# Agent Outputs

output "agent_url" {
  description = "The URL for accessing Agent (custom domain with HTTPS, or ALB DNS with HTTP)"
  value = local.create_agent ? (
    var.agent.domain != null
    ? "https://${var.agent.domain}"
    : "http://${aws_lb.agent[0].dns_name}"
  ) : null
}

output "agent_alb_dns_name" {
  description = "The DNS name of the Agent Application Load Balancer"
  value       = local.create_agent ? aws_lb.agent[0].dns_name : null
}

output "agent_alb_zone_id" {
  description = "The zone ID of the Agent ALB (for Route53 alias records)"
  value       = local.create_agent ? aws_lb.agent[0].zone_id : null
}

output "agent_alb_arn" {
  description = "The ARN of the Agent Application Load Balancer"
  value       = local.create_agent ? aws_lb.agent[0].arn : null
}

output "agent_target_group_arn" {
  description = "The ARN of the Agent target group"
  value       = local.create_agent ? aws_lb_target_group.agent[0].arn : null
}

output "agent_service_name" {
  description = "The name of the Agent ECS service"
  value       = local.create_agent ? aws_ecs_service.agent[0].name : null
}

output "agent_task_definition_arn" {
  description = "The ARN of the Agent task definition"
  value       = local.create_agent ? aws_ecs_task_definition.agent[0].arn : null
}

output "agent_log_group_name" {
  description = "The name of the Agent CloudWatch log group"
  value       = local.create_agent ? aws_cloudwatch_log_group.agent[0].name : null
}

# Security Group Outputs

output "brms_alb_security_group_id" {
  description = "The ID of the BRMS ALB security group"
  value       = local.create_brms ? aws_security_group.brms_alb[0].id : null
}

output "brms_tasks_security_group_id" {
  description = "The ID of the BRMS tasks security group (use for database ingress rules)"
  value       = local.create_brms ? aws_security_group.brms_tasks[0].id : null
}

output "agent_alb_security_group_id" {
  description = "The ID of the Agent ALB security group"
  value       = local.create_agent ? aws_security_group.agent_alb[0].id : null
}

output "agent_tasks_security_group_id" {
  description = "The ID of the Agent tasks security group"
  value       = local.create_agent ? aws_security_group.agent_tasks[0].id : null
}

# IAM Role Outputs

output "ecs_task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "brms_task_role_arn" {
  description = "The ARN of the BRMS task role"
  value       = local.create_brms ? aws_iam_role.brms_task[0].arn : null
}

output "agent_task_role_arn" {
  description = "The ARN of the Agent task role"
  value       = local.create_agent ? aws_iam_role.agent_task[0].arn : null
}

# Secrets Manager Outputs

output "cookie_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the BRMS cookie secret"
  value       = local.create_brms ? aws_secretsmanager_secret.cookie_secret[0].arn : null
}

output "secrets_master_key_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the BRMS secrets master key (null if using aws-kms provider)"
  value       = local.use_env_secrets_provider ? aws_secretsmanager_secret.secrets_master_key[0].arn : null
}

# KMS Outputs

output "brms_kms_key_arn" {
  description = "The ARN of the KMS key created for BRMS secrets encryption (null if using env provider or existing key)"
  value       = local.create_kms_key ? aws_kms_key.brms_secrets[0].arn : null
}

output "brms_kms_key_id" {
  description = "The ID of the KMS key used for BRMS secrets encryption (null if using env provider)"
  value       = local.brms_kms_key_id
}

# Certificate Outputs

output "brms_certificate_arn" {
  description = "The ARN of the BRMS ACM certificate (created or provided)"
  value       = local.create_brms ? local.brms_certificate_arn : null
}

output "agent_certificate_arn" {
  description = "The ARN of the Agent ACM certificate (created or provided)"
  value       = local.create_agent ? local.agent_certificate_arn : null
}
