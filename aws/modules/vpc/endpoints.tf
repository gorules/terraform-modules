locals {
  # Base interface endpoints needed for ECS Fargate to pull images from ECR,
  # ship logs, and read secrets without a NAT gateway. The S3 gateway endpoint
  # (below) is also required because ECR stores image layers in S3.
  base_interface_endpoints = ["ecr.api", "ecr.dkr", "logs", "secretsmanager", "sts"]

  interface_endpoints = local.create_endpoints ? toset(concat(
    local.base_interface_endpoints,
    var.additional_interface_endpoints,
  )) : toset([])
}

resource "aws_security_group" "vpc_endpoints" {
  count = local.create_endpoints ? 1 : 0

  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-vpc-endpoints-sg"
  })
}

resource "aws_vpc_endpoint" "s3" {
  count = local.create_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${replace(each.key, ".", "-")}-endpoint"
  })
}

# Migrate the previously separate interface endpoint resources into the
# for_each map so existing endpoints are not destroyed and recreated.
moved {
  from = aws_vpc_endpoint.ecr_api[0]
  to   = aws_vpc_endpoint.interface["ecr.api"]
}

moved {
  from = aws_vpc_endpoint.ecr_dkr[0]
  to   = aws_vpc_endpoint.interface["ecr.dkr"]
}

moved {
  from = aws_vpc_endpoint.logs[0]
  to   = aws_vpc_endpoint.interface["logs"]
}

moved {
  from = aws_vpc_endpoint.secretsmanager[0]
  to   = aws_vpc_endpoint.interface["secretsmanager"]
}

moved {
  from = aws_vpc_endpoint.sts[0]
  to   = aws_vpc_endpoint.interface["sts"]
}
