locals {
  port                   = 5432
  parameter_group_family = "aurora-postgresql${split(".", var.engine_version)[0]}"
}

resource "terraform_data" "auto_pause_validation" {
  count = var.seconds_until_auto_pause != null ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.min_capacity == 0
      error_message = "seconds_until_auto_pause requires min_capacity = 0. Auto-pause only works when the cluster can scale to 0 ACUs."
    }
  }
}

resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/cluster/${var.name_prefix}-aurora/postgresql"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-postgresql-logs"
  })
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.name_prefix}-aurora"
  description = "Subnet group for Aurora Serverless v2 cluster"
  subnet_ids  = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora"
  })
}

resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${var.name_prefix}-aurora-params"
  family      = local.parameter_group_family
  description = "Aurora PostgreSQL parameter group for ${var.name_prefix}"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-params"
  })
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.name_prefix}-aurora"

  engine         = "aurora-postgresql"
  engine_mode    = "provisioned"
  engine_version = var.engine_version

  database_name   = var.database_name
  master_username = var.master_username
  master_password = random_password.master.result
  port            = local.port

  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  serverlessv2_scaling_configuration {
    min_capacity             = var.min_capacity
    max_capacity             = var.max_capacity
    seconds_until_auto_pause = var.seconds_until_auto_pause
  }

  storage_encrypted                   = true
  deletion_protection                 = var.deletion_protection
  iam_database_authentication_enabled = var.auth == "iam"

  backup_retention_period = var.backup_retention_period
  preferred_backup_window = "03:00-04:00"

  preferred_maintenance_window = "sun:04:00-sun:05:00"
  apply_immediately            = var.apply_immediately

  skip_final_snapshot       = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "${var.name_prefix}-aurora-final" : null

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora"
  })

  lifecycle {
    ignore_changes = [
      availability_zones,
    ]
  }

  depends_on = [aws_cloudwatch_log_group.postgresql]
}

resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${var.name_prefix}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id

  instance_class = "db.serverless"
  engine         = aws_rds_cluster.this.engine
  engine_version = aws_rds_cluster.this.engine_version

  publicly_accessible = false

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-${count.index}"
  })
}
