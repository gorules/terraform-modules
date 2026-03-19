# ECS Module

ECS Fargate services for BRMS and Agent — ALBs, security groups, IAM, secrets, certs, monitoring, autoscaling.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | ECS cluster, RDS CA bundle fetch |
| `brms.tf` | BRMS service: ALB, task definition, service, env vars |
| `agent.tf` | Agent service: ALB, task definition, service, env vars |
| `security.tf` | Security groups for ALBs and tasks |
| `iam.tf` | IAM roles and policies |
| `secrets.tf` | Cookie secret, master key, KMS |
| `certificates.tf` | ACM certificates, Route53 records |
| `monitoring.tf` | CloudWatch alarms |
| `autoscaling.tf` | Application Auto Scaling |
| `variables.tf` | Input variables |
| `outputs.tf` | Module outputs |

## ECS Cluster (`main.tf`)

| Resource | Purpose |
|----------|---------|
| `data.http.rds_ca_bundle` | Fetches RDS CA cert for SSL verification |
| `aws_ecs_cluster` | Cluster with Container Insights enabled |
| `aws_ecs_cluster_capacity_providers` | FARGATE provider (base=1, weight=100) |

> **Known issue**: RDS CA bundle fetch runs unconditionally, even in agent-only deployments.

## BRMS Service (`brms.tf`)

### Infrastructure

| Resource | Purpose |
|----------|---------|
| `aws_cloudwatch_log_group.brms` | Log group: `/ecs/{name}/brms` |
| `aws_lb.brms` | Internet-facing ALB in public subnets |
| `aws_lb_target_group.brms` | IP target group, health check on `/api/health` |
| `aws_lb_listener.brms_http` | Port 80 → redirect to HTTPS (301) |
| `aws_lb_listener.brms_https` | Port 443, TLS 1.3, forward to target group |
| `aws_ecs_task_definition.brms` | Fargate task (awsvpc, X86_64) |
| `aws_ecs_service.brms` | Fargate service with circuit breaker |

### BRMS Requires HTTPS

BRMS uses browser APIs (Web Crypto, Service Workers) that only work in secure contexts. Without HTTPS, it shows a blank page. See [Certificates and DNS](certificates-and-dns.md).

### Environment Variables

The BRMS container gets a dynamically-constructed set of env vars:

| Category | Variables | Conditional |
|----------|-----------|-------------|
| Base | DB_HOST, DB_PORT, DB_USER, DB_NAME, APP_URL | Always |
| Storage | S3_PROVIDER, S3_BUCKET_NAME, S3_REGION | If storage enabled |
| SSL | DB_SSL_CA (base64 RDS cert) or DB_REJECT_UNAUTHORIZED | Always |
| IAM Auth | DB_CREDENTIALS_PROVIDER=aws-iam | If db auth="iam" |
| Secrets Provider | SECRETS_PROVIDER=env or aws-kms | Always |
| KMS | SECRETS_AWS_KMS_KEY_ID | If KMS provider |
| AI | LLM_PROVIDER, LLM_MODEL, LLM_TEMPERATURE, etc. | If AI enabled |

### Secrets (from Secrets Manager)

| Secret | Source | Conditional |
|--------|--------|-------------|
| LICENSE_KEY | User-provided ARN | Always |
| COOKIE_SECRET | Auto-generated (64 chars) | Always |
| DB_PASSWORD | Database credentials secret | If db auth="secrets" |
| SECRETS_MASTER_KEY | Auto-generated | If secrets_provider="env" |
| LLM_API_KEY | User-provided ARN | If AI enabled (not bedrock) |

See [Secrets Management](secrets-management.md) for details.

### Service Configuration

- **Launch type**: FARGATE
- **Network**: Private subnets, no public IP
- **Deployment**: Circuit breaker with rollback, max 200% / min 100%
- **Health check grace period**: 60s (configurable)
- **AZ rebalancing**: Enabled
- **desired_count**: Ignored after creation (managed by [autoscaling](monitoring-and-autoscaling.md))

## Agent Service (`agent.tf`)

Simpler than BRMS:
- No database configuration
- No secrets provider
- No AI configuration
- HTTP-only is allowed (HTTPS optional)
- Default port: 8080 (vs BRMS 80)
- Read-only S3 access (vs read-write for BRMS)

HTTPS is optional: if no `certificate_arn` or `route53_zone_id`, the HTTP listener forwards directly instead of redirecting.

## Security Groups (`security.tf`)

Each service gets two security groups. See [Security Architecture](security-architecture.md) for the full model.

### Per Service (BRMS and Agent)

| SG | Rules |
|-----|------|
| ALB SG | Ingress: HTTP (80) + HTTPS (443) from `allowed_cidr_blocks` |
| | Egress: Container port to Task SG |
| Task SG | Ingress: Container port from ALB SG |
| | Egress: 0.0.0.0/0 all protocols (wide open) |

> **Known issue**: Task egress is 0.0.0.0/0. Could be tightened with [VPC endpoints](vpc-module.md).

## IAM (`iam.tf`)

See [IAM Architecture](iam-architecture.md) for the complete IAM model. Key roles:
- **Task execution role** — Shared, pulls images + reads secrets
- **BRMS task role** — S3 read-write, optional KMS, Bedrock, external buckets
- **Agent task role** — S3 read-only

## Fargate CPU/Memory Matrix

Valid combinations enforced by variable validation:

| CPU (units) | Memory Range (MiB) |
|-------------|--------------------|
| 256 | 512, 1024, 2048 |
| 512 | 1024 - 4096 |
| 1024 | 2048 - 8192 |
| 2048 | 4096 - 16384 |
| 4096 | 8192 - 30720 |
| 8192 | 16384 - 61440 |
| 16384 | 32768 - 122880 |
