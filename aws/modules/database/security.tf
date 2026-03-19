resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-aurora-sg"
  description = "Security group for Aurora Serverless v2 PostgreSQL cluster"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_from_security_groups" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  description              = "PostgreSQL access from allowed security group"
  from_port                = local.port
  to_port                  = local.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.allowed_security_group_ids[count.index]
}
