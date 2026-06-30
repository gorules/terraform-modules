# GoRules Terraform Modules

Terraform modules for deploying [GoRules](https://gorules.io) on cloud infrastructure.

## Available Modules

| Cloud | Path | Description |
|-------|------|-------------|
| AWS | [aws/](aws/) | ECS Fargate deployment with Aurora Serverless v2, S3, ALB |

## What is GoRules?

GoRules is a Business Rules Management System (BRMS) for managing and executing business rules. It has two components:

- **BRMS** - Management UI and API for creating, editing, and publishing rules. Requires a database and S3 storage.
- **Agent** - Stateless rule execution engine that pulls published rules from S3. Scales independently from BRMS.

## Getting Started

See the [AWS module documentation](aws/) for usage instructions and examples.

## Documentation

Full documentation is in the [project Wiki](https://github.com/gorules/terraform-modules/wiki).
