# Root Module (`aws/`)

The only module you call directly. Child modules are internal.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Module composition + precondition validations |
| `variables.tf` | Top-level structured object variables |
| `outputs.tf` | Root outputs (33 values) |
| `locals.tf` | Component creation flags, cross-module wiring |
| `data.tf` | aws_region, aws_caller_identity, aws_availability_zones |
| `versions.tf` | Provider requirements |

## Module Composition (`main.tf`)

The root module conditionally instantiates four child modules:

```hcl
module "vpc" {
  count  = local.create_vpc ? 1 : 0
  source = "./modules/vpc"
  # ...
}

module "storage" {
  count  = local.create_storage ? 1 : 0
  source = "./modules/storage"
  # ...
}

module "database" {
  count      = local.create_database ? 1 : 0
  source     = "./modules/database"
  depends_on = [module.vpc]
  # ...
}

module "ecs" {
  count      = local.create_ecs ? 1 : 0
  source     = "./modules/ecs"
  depends_on = [module.vpc, module.storage, module.database]
  # ...
}
```

## Precondition Validations

Three `terraform_data` resources enforce dependency rules:

1. **brms_dependencies** — BRMS requires both [Database Module](database-module.md) and [Storage Module](storage-module.md)
2. **agent_dependencies** — Agent requires [Storage Module](storage-module.md)
3. **vpc_validation** — Existing VPC mode requires `vpc.id` + subnet IDs

## Creation Flags (`locals.tf`)

Boolean flags control which modules are instantiated:

```hcl
locals {
  create_vpc      = var.vpc != null && var.vpc.create
  create_storage  = var.storage != null
  create_bucket   = local.create_storage && var.storage.create_bucket
  create_database = var.database != null
  create_brms     = var.brms != null
  create_agent    = var.agent != null
  create_ecs      = local.create_brms || local.create_agent
}
```

## Cross-Module Wiring

The root `main.tf` handles cross-module security group rules:

```hcl
resource "aws_security_group_rule" "database_from_brms" {
  count                    = local.create_brms && local.create_database ? 1 : 0
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.ecs[0].brms_tasks_security_group_id
  security_group_id        = module.database[0].security_group_id
}
```

This allows BRMS ECS tasks to connect to the Aurora database. See [Security Architecture](security-architecture.md) for details.

## Data Flow

See [Variable System](variable-system.md) for how configuration flows from root variables to child modules.
