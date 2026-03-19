resource "terraform_data" "brms_dependencies" {
  count = local.create_brms ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.create_database
      error_message = "BRMS requires database to be enabled. Please configure the 'database' variable."
    }

    precondition {
      condition     = local.create_storage || length(coalesce(var.brms.external_buckets, [])) > 0
      error_message = "BRMS requires either local storage or external_buckets to be configured."
    }
  }
}

resource "terraform_data" "agent_dependencies" {
  count = local.create_agent ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.create_storage
      error_message = "Agent requires storage to be enabled. Please configure the 'storage' variable."
    }
  }
}

resource "terraform_data" "vpc_validation" {
  count = !local.create_vpc && var.vpc != null ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.vpc.id != null
      error_message = "When create=false, vpc.id is required."
    }

    precondition {
      condition     = length(var.vpc.private_subnet_ids) >= 1
      error_message = "When create=false, at least one private subnet ID is required."
    }

    precondition {
      condition     = length(var.vpc.public_subnet_ids) >= 1
      error_message = "When create=false, at least one public subnet ID is required."
    }
  }
}

module "vpc" {
  source = "./modules/vpc"
  count  = local.create_vpc ? 1 : 0

  name_prefix          = local.name_prefix
  cidr                 = var.vpc.cidr
  availability_zones   = local.availability_zones
  nat_gateway_mode     = var.vpc.nat_gateway_mode
  enable_vpc_endpoints = var.vpc.enable_vpc_endpoints
  tags                 = local.tags
}

module "storage" {
  source = "./modules/storage"
  count  = local.create_storage ? 1 : 0

  name_prefix                    = local.name_prefix
  storage                        = var.storage
  cross_account_write_principals = coalesce(var.storage.cross_account_write_principals, [])
  tags                           = local.tags
}

module "database" {
  source = "./modules/database"
  count  = local.create_database ? 1 : 0

  name_prefix                = local.name_prefix
  vpc_id                     = local.vpc_id
  private_subnet_ids         = local.private_subnet_ids
  engine_version             = var.database.engine_version
  instance_count             = var.database.instance_count
  min_capacity               = var.database.min_capacity
  max_capacity               = var.database.max_capacity
  seconds_until_auto_pause   = var.database.seconds_until_auto_pause
  master_username            = var.database.master_username
  database_name              = local.database_name
  deletion_protection        = var.database.deletion_protection
  backup_retention_period    = var.database.backup_retention_period
  apply_immediately          = var.database.apply_immediately
  allowed_security_group_ids = []
  auth                       = var.database.auth
  iam_username               = var.database.iam_username
  tags                       = local.tags

  depends_on = [module.vpc]
}

module "ecs" {
  source = "./modules/ecs"
  count  = local.create_ecs ? 1 : 0

  name_prefix        = local.name_prefix
  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids
  public_subnet_ids  = local.public_subnet_ids

  brms  = var.brms
  agent = var.agent

  alarm_sns_topic_arn = var.alarm_sns_topic_arn

  database = local.create_brms && local.create_database ? {
    endpoint                   = module.database[0].endpoint
    port                       = module.database[0].port
    name                       = module.database[0].database_name
    username                   = module.database[0].auth_method == "iam" ? module.database[0].iam_username : module.database[0].master_username
    credentials_secret_arn     = module.database[0].credentials_secret_arn
    secrets_read_policy_arn    = module.database[0].secrets_read_policy_arn
    auth                       = module.database[0].auth_method
    rds_iam_connect_policy_arn = module.database[0].rds_iam_connect_policy_arn
  } : null

  storage = local.create_storage ? {
    bucket_name              = local.bucket_name
    bucket_arn               = local.bucket_arn
    iam_policy_arn           = module.storage[0].iam_policy_arn
    iam_read_only_policy_arn = module.storage[0].iam_read_only_policy_arn
  } : null

  brms_external_buckets = var.brms != null ? coalesce(var.brms.external_buckets, []) : []

  tags = local.tags

  depends_on = [
    module.vpc,
    module.storage,
    module.database,
    terraform_data.brms_dependencies,
    terraform_data.agent_dependencies
  ]
}

resource "aws_security_group_rule" "database_from_brms" {
  count = local.create_brms && local.create_database ? 1 : 0

  type                     = "ingress"
  from_port                = local.database_port
  to_port                  = local.database_port
  protocol                 = "tcp"
  source_security_group_id = module.ecs[0].brms_tasks_security_group_id
  security_group_id        = module.database[0].security_group_id
  description              = "Allow BRMS ECS tasks to connect to Aurora"
}
