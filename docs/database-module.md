# Database Module

Aurora Serverless v2 PostgreSQL with optional IAM auth and a Lambda for user provisioning.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Aurora cluster, instances, parameter group, subnet group |
| `security.tf` | Database security group |
| `iam.tf` | RDS IAM connect policy |
| `secrets.tf` | Secrets Manager for credentials |
| `lambda.tf` | IAM user setup Lambda function |
| `lambda/iam_user_setup.py` | Python handler for PostgreSQL IAM user creation |
| `lambda/layers/psycopg_layer.zip` | Pre-built psycopg PostgreSQL adapter layer |
| `variables.tf` | Input variables |
| `outputs.tf` | Module outputs |

## Aurora Serverless v2 Cluster (`main.tf`)

| Resource | Purpose |
|----------|---------|
| `aws_cloudwatch_log_group.postgresql` | Log group: `/aws/rds/cluster/{name}-aurora/postgresql`, 30-day retention |
| `aws_db_subnet_group` | Private subnets from [VPC Module](vpc-module.md) (requires >= 2 subnets) |
| `random_password.master` | 32-char master password |
| `aws_rds_cluster_parameter_group` | Enforces `rds.force_ssl = 1` |
| `aws_rds_cluster` | Aurora PostgreSQL cluster (serverless v2) |
| `aws_rds_cluster_instance` | Individual instances (count = var.instance_count) |

### Cluster Configuration

- **Engine**: `aurora-postgresql` (default version 17.4)
- **Scaling**: Min/max ACUs (0-256), auto-pause support
- **Storage**: Encrypted at rest
- **SSL**: Forced via parameter group (`rds.force_ssl = 1`)
- **Backup**: Configurable retention (1-35 days, default 7)
- **Windows**: Backup 03:00-04:00 UTC, maintenance Sun 04:00-05:00 UTC
- **Final snapshot**: Created if deletion_protection=true, skipped otherwise

### Auto-Pause (Serverless v2)

Requires `min_capacity = 0`. Range: 300-86400 seconds (5 min to 24 hours).

```hcl
database = {
  min_capacity             = 0
  max_capacity             = 4
  seconds_until_auto_pause = 300  # 5 minutes
}
```

## Authentication Modes

Two modes controlled by `database.auth`:

### Secrets Mode (default: `auth = "secrets"`)

- Master credentials stored in Secrets Manager
- BRMS reads DB_PASSWORD from Secrets Manager at runtime
- See [Secrets Management](secrets-management.md) for details

### IAM Mode (`auth = "iam"`)

- Enables `iam_database_authentication_enabled` on the cluster
- Triggers Lambda function to create PostgreSQL IAM user
- BRMS uses temporary IAM credentials instead of passwords
- See [IAM Architecture](iam-architecture.md) for the IAM connect policy

## Lambda IAM User Setup (`lambda.tf`)

Only created when `auth = "iam"`.

### Resources

| Resource | Purpose |
|----------|---------|
| `aws_security_group.lambda` | Lambda function SG |
| SG rules | Lambda → Aurora (5432), Lambda → internet (443), Aurora ← Lambda |
| `aws_iam_role.lambda` | Lambda execution role |
| `aws_lambda_layer_version.psycopg` | psycopg PostgreSQL adapter (Python 3.14) |
| `aws_lambda_function.iam_user_setup` | The function itself (120s timeout, 256 MB) |
| `aws_lambda_invocation.create_iam_user` | Invokes at apply time |

### What the Lambda Does (`iam_user_setup.py`)

1. Retrieves master credentials from [Secrets Manager](secrets-management.md)
2. Connects to Aurora with SSL (`sslmode=require`)
3. Checks if IAM user exists: `SELECT 1 FROM pg_roles WHERE rolname = ...`
4. Creates user if missing: `CREATE USER "gorules_user" WITH LOGIN`
5. Grants IAM role: `GRANT rds_iam TO "gorules_user"`
6. Creates database if needed: `CREATE DATABASE "gorules"`
7. Sets ownership: `ALTER DATABASE "gorules" OWNER TO "gorules_user"`

### Lambda Networking

The Lambda runs in the VPC (private subnets) with its own security group. Three SG rules wire it:
- **Egress to Aurora** (port 5432) — connect to database
- **Egress HTTPS** (port 443) — reach Secrets Manager API
- **Ingress on Aurora SG** — allow Lambda's SG to connect

## Security Group (`security.tf`)

A single SG for the Aurora cluster. Ingress rules added dynamically:
- `allowed_security_group_ids` — list of SGs that can connect
- Cross-module rule from [Root Module](root-module.md) allows BRMS task SG

## Credentials in Secrets Manager (`secrets.tf`)

Always created regardless of auth mode:

```json
{
  "username": "gorules_admin",
  "password": "<random_32_char>",
  "engine": "postgres",
  "host": "<cluster_endpoint>",
  "port": 5432,
  "dbname": "gorules",
  "dbClusterIdentifier": "<cluster_id>",
  "clusterResourceId": "<resource_id>",
  "readerEndpoint": "<reader_endpoint>"
}
```

## Key Variables

```hcl
database = {
  engine_version           = "17.4"
  instance_count           = 1
  min_capacity             = 0.5   # ACUs (required)
  max_capacity             = 4     # ACUs (required)
  seconds_until_auto_pause = null  # requires min_capacity=0
  master_username          = "gorules_admin"
  deletion_protection      = true
  backup_retention_period  = 7     # 1-35 days
  auth                     = "secrets"  # or "iam"
  iam_username             = "gorules_user"
}
```

Set `database = null` to disable entirely.

## Key Outputs

- `endpoint`, `reader_endpoint`, `port`
- `database_name`, `master_username`
- `security_group_id` — used by [Root Module](root-module.md) for cross-module SG rule
- `credentials_secret_arn` — used by [ECS Module](ecs-module.md)
- `rds_iam_connect_policy_arn` — used by [IAM Architecture](iam-architecture.md)
