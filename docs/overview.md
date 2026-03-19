# GoRules Terraform Module Library

Terraform modules for deploying **GoRules** on **AWS ECS Fargate**. One root module (`aws/`) wires up four child modules.

## What is GoRules?

GoRules has two components:

- **BRMS** — Full management UI + API for authoring rules. Requires database + storage + HTTPS.
- **Agent** — Stateless rule execution engine. Requires storage only.

## Module Architecture

The [Root Module](root-module.md) is the single entry point. It conditionally instantiates:

| Module | Purpose | Conditional On |
|--------|---------|----------------|
| [VPC Module](vpc-module.md) | Networking infrastructure | `vpc.create == true` |
| [Storage Module](storage-module.md) | S3 bucket for rule storage | `storage != null` |
| [Database Module](database-module.md) | Aurora Serverless v2 PostgreSQL | `database != null` |
| [ECS Module](ecs-module.md) | ECS Fargate services (BRMS + Agent) | `brms != null OR agent != null` |

## Topics

- [Security Architecture](security-architecture.md) — Network isolation, encryption, TLS
- [IAM Architecture](iam-architecture.md) — Roles, policies, least-privilege
- [Secrets Management](secrets-management.md) — KMS, Secrets Manager, encryption providers
- [Variable System](variable-system.md) — How configuration flows root → child modules
- [Certificates and DNS](certificates-and-dns.md) — ACM certificates, Route53 records
- [Monitoring and Autoscaling](monitoring-and-autoscaling.md) — CloudWatch alarms, auto scaling
- [AI LLM Configuration](ai-llm-configuration.md) — Optional AI assistant setup

## Deployment Patterns

See [Deployment Patterns](deployment-patterns.md) for supported deployment topologies:
- Full Stack (VPC + DB + S3 + BRMS + Agent)
- Agent Only (VPC + S3 + Agent)
- Existing VPC integration
- Multi-environment / cross-account

## Tech Stack

- **Terraform** >= 1.14
- **AWS Provider** >= 6.0
- **AWS Services**: VPC, ECS Fargate, Aurora Serverless v2, S3, ALB, ACM, Route53, Secrets Manager, KMS, CloudWatch, IAM, Lambda

## Design Patterns

1. **Null-disabling** — Set a component to `null` to disable it entirely
2. **Conditional `count`** — All child modules use `count = local.create_X ? 1 : 0`
3. **Structured objects** — Top-level variables are typed `object({})` with `optional()` attributes
4. **Extensive validation** — Regex, range, cross-field, and Fargate CPU/memory matrix validations
5. **Cross-module wiring** — Done in the [Root Module](root-module.md)'s `main.tf`
