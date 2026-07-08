resource "aws_secretsmanager_secret" "credentials" {
  name                    = "${var.name_prefix}-aurora-credentials"
  description             = "Credentials for Aurora Serverless v2 PostgreSQL cluster"
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "credentials" {
  secret_id = aws_secretsmanager_secret.credentials.id
  secret_string = jsonencode({
    username            = var.master_username
    password            = random_password.master.result
    engine              = "postgres"
    host                = aws_rds_cluster.this.endpoint
    port                = local.port
    dbname              = var.database_name
    dbClusterIdentifier = aws_rds_cluster.this.cluster_identifier
    clusterResourceId   = aws_rds_cluster.this.cluster_resource_id
    readerEndpoint      = aws_rds_cluster.this.reader_endpoint
  })
}

data "aws_iam_policy_document" "secrets_read" {
  statement {
    sid    = "AllowReadDatabaseCredentials"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      aws_secretsmanager_secret.credentials.arn
    ]
  }
}

resource "aws_iam_policy" "secrets_read" {
  name        = "${var.name_prefix}-aurora-secrets-read"
  description = "Policy for reading Aurora database credentials from Secrets Manager"
  policy      = data.aws_iam_policy_document.secrets_read.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-secrets-read"
  })
}
