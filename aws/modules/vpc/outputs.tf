# VPC Outputs

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

# Subnet Outputs

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (empty when the VPC is fully private)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_cidr_blocks" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "public_subnet_cidr_blocks" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

# NAT Gateway Outputs

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (empty when nat_gateway_mode = none)"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public IPs associated with NAT Gateways (empty when nat_gateway_mode = none)"
  value       = aws_eip.nat[*].public_ip
}

# Route Table Outputs

output "public_route_table_id" {
  description = "ID of the public route table (null when the VPC has no public subnets)"
  value       = one(aws_route_table.public[*].id)
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

# VPC Endpoint Outputs

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint (null when endpoints are not created)"
  value       = local.create_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_interface_ids" {
  description = "Map of interface VPC endpoint service short-name to endpoint ID"
  value       = { for k, ep in aws_vpc_endpoint.interface : k => ep.id }
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group for VPC endpoints (null when endpoints are not created)"
  value       = local.create_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

# Internet Gateway Output

output "internet_gateway_id" {
  description = "ID of the Internet Gateway (null when the VPC has no public subnets)"
  value       = one(aws_internet_gateway.this[*].id)
}
