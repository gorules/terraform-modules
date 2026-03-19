# Cluster Outputs

output "cluster_id" {
  description = "The ID of the Aurora cluster"
  value       = aws_rds_cluster.this.id
}

output "cluster_identifier" {
  description = "The cluster identifier"
  value       = aws_rds_cluster.this.cluster_identifier
}

output "cluster_resource_id" {
  description = "The Resource ID of the cluster (used for IAM authentication)"
  value       = aws_rds_cluster.this.cluster_resource_id
}

output "cluster_arn" {
  description = "The ARN of the Aurora cluster"
  value       = aws_rds_cluster.this.arn
}

# Endpoint Outputs

output "endpoint" {
  description = "The cluster endpoint (writer)"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "The cluster reader endpoint"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "The database port"
  value       = local.port
}

# Database Outputs

output "database_name" {
  description = "The name of the default database"
  value       = var.database_name
}

output "master_username" {
  description = "The master username"
  value       = var.master_username
}

# Security Group Outputs

output "security_group_id" {
  description = "The ID of the Aurora security group"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "The ARN of the Aurora security group"
  value       = aws_security_group.this.arn
}

# Secrets Manager Outputs

output "credentials_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.credentials.arn
}

output "credentials_secret_name" {
  description = "The name of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.credentials.name
}

output "secrets_read_policy_arn" {
  description = "The ARN of the IAM policy for reading database credentials"
  value       = aws_iam_policy.secrets_read.arn
}

# Instance Outputs

output "instance_identifiers" {
  description = "List of Aurora instance identifiers"
  value       = aws_rds_cluster_instance.this[*].identifier
}

output "instance_arns" {
  description = "List of Aurora instance ARNs"
  value       = aws_rds_cluster_instance.this[*].arn
}

# Authentication Outputs

output "auth_method" {
  description = "Authentication method configured ('secrets' or 'iam')"
  value       = var.auth
}

output "iam_username" {
  description = "PostgreSQL username for IAM auth (null if auth='secrets')"
  value       = var.auth == "iam" ? var.iam_username : null
}

output "rds_iam_connect_policy_arn" {
  description = "IAM policy ARN for rds-db:connect (null if auth='secrets')"
  value       = var.auth == "iam" ? aws_iam_policy.rds_iam_connect[0].arn : null
}

# Lambda Outputs (IAM User Setup)

output "iam_user_setup_lambda_arn" {
  description = "ARN of the Lambda function for IAM user setup (null if not created)"
  value       = local.create_lambda ? aws_lambda_function.iam_user_setup[0].arn : null
}

output "iam_user_setup_result" {
  description = "Result of the IAM user setup Lambda invocation (null if not invoked)"
  value       = local.create_lambda ? jsondecode(aws_lambda_invocation.create_iam_user[0].result) : null
}