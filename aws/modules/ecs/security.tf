resource "aws_security_group" "brms_alb" {
  count = local.create_brms ? 1 : 0

  name        = "${var.name_prefix}-brms-alb-sg"
  description = "Security group for BRMS Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "brms_alb_http_ingress" {
  count = local.create_brms ? 1 : 0

  type              = "ingress"
  description       = "HTTP access from allowed CIDR blocks"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.brms.allowed_cidr_blocks
  security_group_id = aws_security_group.brms_alb[0].id
}

resource "aws_security_group_rule" "brms_alb_https_ingress" {
  count = local.create_brms && local.brms_use_tls ? 1 : 0

  type              = "ingress"
  description       = "HTTPS access from allowed CIDR blocks"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.brms.allowed_cidr_blocks
  security_group_id = aws_security_group.brms_alb[0].id
}

resource "aws_security_group_rule" "brms_alb_egress_to_tasks" {
  count = local.create_brms ? 1 : 0

  type                     = "egress"
  description              = "Allow traffic to BRMS tasks"
  from_port                = var.brms.port
  to_port                  = var.brms.port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.brms_tasks[0].id
  security_group_id        = aws_security_group.brms_alb[0].id
}

resource "aws_security_group" "brms_tasks" {
  count = local.create_brms ? 1 : 0

  name        = "${var.name_prefix}-brms-tasks-sg"
  description = "Security group for BRMS ECS tasks"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-tasks-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "brms_tasks_ingress_from_alb" {
  count = local.create_brms ? 1 : 0

  type                     = "ingress"
  description              = "Allow traffic from BRMS ALB"
  from_port                = var.brms.port
  to_port                  = var.brms.port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.brms_alb[0].id
  security_group_id        = aws_security_group.brms_tasks[0].id
}

resource "aws_security_group_rule" "brms_tasks_egress_all" {
  count = local.create_brms ? 1 : 0

  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.brms_tasks[0].id
}

resource "aws_security_group" "agent_alb" {
  count = local.create_agent ? 1 : 0

  name        = "${var.name_prefix}-agent-alb-sg"
  description = "Security group for Agent Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "agent_alb_http_ingress" {
  count = local.create_agent ? 1 : 0

  type              = "ingress"
  description       = "HTTP access from allowed CIDR blocks"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.agent.allowed_cidr_blocks
  security_group_id = aws_security_group.agent_alb[0].id
}

resource "aws_security_group_rule" "agent_alb_https_ingress" {
  count = local.create_agent && local.agent_use_tls ? 1 : 0

  type              = "ingress"
  description       = "HTTPS access from allowed CIDR blocks"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.agent.allowed_cidr_blocks
  security_group_id = aws_security_group.agent_alb[0].id
}

resource "aws_security_group_rule" "agent_alb_egress_to_tasks" {
  count = local.create_agent ? 1 : 0

  type                     = "egress"
  description              = "Allow traffic to Agent tasks"
  from_port                = var.agent.port
  to_port                  = var.agent.port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.agent_tasks[0].id
  security_group_id        = aws_security_group.agent_alb[0].id
}

resource "aws_security_group" "agent_tasks" {
  count = local.create_agent ? 1 : 0

  name        = "${var.name_prefix}-agent-tasks-sg"
  description = "Security group for Agent ECS tasks"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-tasks-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "agent_tasks_ingress_from_alb" {
  count = local.create_agent ? 1 : 0

  type                     = "ingress"
  description              = "Allow traffic from Agent ALB"
  from_port                = var.agent.port
  to_port                  = var.agent.port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.agent_alb[0].id
  security_group_id        = aws_security_group.agent_tasks[0].id
}

resource "aws_security_group_rule" "agent_tasks_egress_all" {
  count = local.create_agent ? 1 : 0

  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.agent_tasks[0].id
}
