# VPC Module

VPC with public/private subnets, NAT gateways, IGW, and optional VPC endpoints.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | VPC, subnets, NAT, IGW, route tables |
| `endpoints.tf` | VPC endpoints for S3, ECR, Logs, SM, STS |
| `variables.tf` | Input variables |
| `outputs.tf` | Module outputs |

## Resources Created

### Core Networking (`main.tf`)

| Resource | Count | Purpose |
|----------|-------|---------|
| `aws_vpc` | 1 | VPC with DNS hostnames + support enabled |
| `aws_internet_gateway` | 1 | Internet access for public subnets |
| `aws_subnet.public` | 1 per AZ | Public subnets (`cidrsubnet(cidr, 8, index)`) |
| `aws_subnet.private` | 1 per AZ | Private subnets (`cidrsubnet(cidr, 8, index + 128)`) |
| `aws_eip.nat` | 1 or N | Elastic IPs for NAT gateways |
| `aws_nat_gateway` | 1 or N | NAT for private subnet egress |
| `aws_route_table.public` | 1 | Routes: 0.0.0.0/0 → IGW |
| `aws_route_table.private` | 1 or N | Routes: 0.0.0.0/0 → NAT GW |

### Subnet CIDR Calculation

With default CIDR `10.0.0.0/16`:
- **Public subnets**: `10.0.0.0/24`, `10.0.1.0/24`, `10.0.2.0/24`...
- **Private subnets**: `10.0.128.0/24`, `10.0.129.0/24`, `10.0.130.0/24`...

### NAT Gateway Modes

| Mode | NAT Gateways | Route Tables | Cost | Use Case |
|------|-------------|-------------|------|----------|
| `single` | 1 | 1 shared | Lower | Dev/staging |
| `ha` | 1 per AZ | 1 per AZ | Higher | Production |

In `ha` mode, each private subnet routes through its own AZ's NAT gateway, providing resilience.

## VPC Endpoints (`endpoints.tf`)

Conditional on `enable_vpc_endpoints = true`. Reduces NAT costs and improves security.

| Endpoint | Type | Purpose |
|----------|------|---------|
| S3 | Gateway | S3 access without NAT (used by [Storage Module](storage-module.md)) |
| ECR API | Interface | Pull container images (used by [ECS Module](ecs-module.md)) |
| ECR DKR | Interface | Docker layer downloads |
| CloudWatch Logs | Interface | Log shipping |
| Secrets Manager | Interface | Secret retrieval (used by [Secrets Management](secrets-management.md)) |
| STS | Interface | IAM temporary credentials |

All interface endpoints use a shared security group allowing HTTPS (443) from VPC CIDR.

## How Other Modules Use This

- [ECS Module](ecs-module.md) — ALBs in public subnets, tasks in private subnets
- [Database Module](database-module.md) — Aurora cluster in private subnets via `aws_db_subnet_group`
- [Security Architecture](security-architecture.md) — SGs reference VPC ID for network isolation

## Key Variables

```hcl
vpc = {
  create               = true          # false → use existing VPC
  cidr                 = "10.0.0.0/16"
  availability_zones   = []            # auto-selects first 2 AZs
  nat_gateway_mode     = "single"      # or "ha"
  enable_vpc_endpoints = false
  # For existing VPC:
  id                   = null
  private_subnet_ids   = []
  public_subnet_ids    = []
}
```

## Outputs

- `vpc_id`, `vpc_cidr_block`
- `private_subnet_ids`, `public_subnet_ids` + CIDRs
- `nat_gateway_ids`, `nat_gateway_public_ips`
- `public_route_table_id`, `private_route_table_ids`
- `vpc_endpoint_s3_id`, `vpc_endpoints_security_group_id`
