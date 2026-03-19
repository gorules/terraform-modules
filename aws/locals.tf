locals {
  name_prefix = "${var.project_name}-${var.environment}"

  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

locals {
  create_vpc      = var.vpc != null && var.vpc.create
  create_storage  = var.storage != null
  create_bucket   = local.create_storage && var.storage.create_bucket
  create_database = var.database != null
  create_brms     = var.brms != null
  create_agent    = var.agent != null
  create_ecs      = local.create_brms || local.create_agent
}

locals {
  availability_zones = (
    var.vpc != null && length(var.vpc.availability_zones) > 0
    ? var.vpc.availability_zones
    : slice(data.aws_availability_zones.available.names, 0, 2)
  )

  az_count           = length(local.availability_zones)
  vpc_id             = local.create_vpc ? module.vpc[0].vpc_id : var.vpc.id
  private_subnet_ids = local.create_vpc ? module.vpc[0].private_subnet_ids : var.vpc.private_subnet_ids
  public_subnet_ids  = local.create_vpc ? module.vpc[0].public_subnet_ids : var.vpc.public_subnet_ids
}

locals {
  bucket_name  = local.create_bucket ? module.storage[0].bucket_name : var.storage.existing_bucket_name
  bucket_arn   = local.create_bucket ? module.storage[0].bucket_arn : var.storage.existing_bucket_arn
  storage_auth = local.create_storage ? var.storage.auth : null
}

locals {
  database_name = "gorules"
  database_port = 5432
}

locals {
  brms_url  = local.create_brms && local.create_ecs ? module.ecs[0].brms_url : null
  agent_url = local.create_agent && local.create_ecs ? module.ecs[0].agent_url : null
}

locals {
  brms_dependencies_met  = !local.create_brms || (local.create_database && local.create_storage)
  agent_dependencies_met = !local.create_agent || local.create_storage
}
