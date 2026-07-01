data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "http" "rds_ca_bundle" {
  url = "https://truststore.pki.rds.amazonaws.com/${data.aws_region.current.region}/${data.aws_region.current.region}-bundle.pem"
}

locals {
  create_brms  = var.brms != null
  create_agent = var.agent != null

  common_tags = merge(var.tags, {
    Module = "ecs"
  })

  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  rds_ca_cert_base64 = base64encode(data.http.rds_ca_bundle.response_body)
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-cluster"
  })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
