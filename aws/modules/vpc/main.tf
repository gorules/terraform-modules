data "aws_region" "current" {}

locals {
  az_count = length(var.availability_zones)

  nat_enabled       = var.nat_gateway_mode != "none"
  nat_gateway_count = local.nat_enabled ? (var.nat_gateway_mode == "ha" ? local.az_count : 1) : 0

  # Private route tables always exist (independent of NAT) so the S3 gateway
  # endpoint has a route table to attach to and private subnets get explicit
  # associations.
  private_rt_count = var.nat_gateway_mode == "ha" ? local.az_count : 1

  # Public subnets (and the internet gateway) exist when an internet-facing ALB
  # needs them, or to host a NAT gateway. With nat_gateway_mode = "none" and no
  # internet-facing ALB the VPC is fully private (no public subnets, internet
  # gateway, NAT gateway or EIP), which satisfies policies that forbid creating
  # any resource in a public subnet.
  create_public = var.create_public_subnets || local.nat_enabled

  # With no NAT gateway, VPC endpoints are the only path to AWS services, so
  # create them automatically in that case.
  create_endpoints = var.enable_vpc_endpoints || !local.nat_enabled

  common_tags = merge(var.tags, {
    Module = "vpc"
  })
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  count = local.create_public ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# Preserve state for VPCs created before the internet gateway became optional.
moved {
  from = aws_internet_gateway.this
  to   = aws_internet_gateway.this[0]
}

resource "aws_subnet" "public" {
  count = local.create_public ? local.az_count : 0

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
    Type = "public"
  })
}

resource "aws_subnet" "private" {
  count = local.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr, 8, count.index + 128)
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-private-subnet-${count.index + 1}"
    Type = "private"
  })
}

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  count = local.create_public ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

# Preserve state for VPCs created before the public route table became optional.
moved {
  from = aws_route_table.public
  to   = aws_route_table.public[0]
}

resource "aws_route" "public_internet" {
  count = local.create_public ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

moved {
  from = aws_route.public_internet
  to   = aws_route.public_internet[0]
}

resource "aws_route_table_association" "public" {
  count = local.create_public ? local.az_count : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count = local.private_rt_count

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = var.nat_gateway_mode == "ha" ? "${var.name_prefix}-private-rt-${count.index + 1}" : "${var.name_prefix}-private-rt"
  })
}

resource "aws_route" "private_nat" {
  count = local.nat_gateway_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  count = local.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.nat_gateway_mode == "ha" ? count.index : 0].id
}
