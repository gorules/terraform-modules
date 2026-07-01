resource "aws_cloudwatch_log_group" "agent" {
  count = local.create_agent ? 1 : 0

  name              = "/ecs/${var.name_prefix}/agent"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-logs"
  })
}

resource "aws_lb" "agent" {
  count = local.create_agent ? 1 : 0

  name               = "${var.name_prefix}-agent-alb"
  internal           = var.agent.alb_internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.agent_alb[0].id]
  subnets            = var.agent.alb_internal ? var.private_subnet_ids : var.public_subnet_ids

  idle_timeout               = var.agent.alb_idle_timeout
  enable_deletion_protection = var.agent.alb_deletion_protection

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-alb"
  })

  lifecycle {
    precondition {
      condition     = var.agent.alb_internal || length(var.public_subnet_ids) > 0
      error_message = "Agent ALB is internet-facing but no public subnets were provided. Set agent.alb_internal = true to place it in private subnets, or pass public_subnet_ids."
    }

    precondition {
      condition     = length(var.agent.alb_internal ? var.private_subnet_ids : var.public_subnet_ids) >= 2
      error_message = "The Agent ALB requires at least 2 subnets in different Availability Zones (private subnets when alb_internal = true, otherwise public subnets)."
    }
  }
}

resource "aws_lb_target_group" "agent" {
  count = local.create_agent ? 1 : 0

  name                 = "${var.name_prefix}-agent-tg"
  port                 = var.agent.port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = var.agent.deregistration_delay

  health_check {
    enabled             = true
    path                = var.agent.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "agent_http" {
  count = local.create_agent ? 1 : 0

  load_balancer_arn = aws_lb.agent[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = local.agent_use_tls ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = local.agent_use_tls ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = local.agent_use_tls ? null : aws_lb_target_group.agent[0].arn
  }
}

resource "aws_lb_listener" "agent_https" {
  count = local.create_agent && local.agent_use_tls ? 1 : 0

  load_balancer_arn = aws_lb.agent[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.agent_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.agent[0].arn
  }

  depends_on = [aws_acm_certificate_validation.agent]
}

locals {
  agent_base_env = var.agent != null ? [
    {
      name  = "PROVIDER__TYPE"
      value = "S3"
    },
    {
      name  = "PROVIDER__BUCKET"
      value = var.storage.bucket_name
    },
    {
      name  = "PROVIDER__REGION"
      value = local.region
    }
  ] : []

  agent_environment = var.agent != null ? concat(
    local.agent_base_env,
    var.agent.env
  ) : []

  agent_secrets = var.agent != null ? var.agent.secrets : []
}

resource "aws_ecs_task_definition" "agent" {
  count = local.create_agent ? 1 : 0

  family                   = "${var.name_prefix}-agent"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.agent.cpu
  memory                   = var.agent.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.agent_task[0].arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "agent"
      image     = var.agent.image
      essential = true

      portMappings = [
        {
          containerPort = var.agent.port
          hostPort      = var.agent.port
          protocol      = "tcp"
        }
      ]

      environment = local.agent_environment
      secrets     = length(local.agent_secrets) > 0 ? local.agent_secrets : null

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.agent[0].name
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "agent"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent"
  })
}

resource "aws_ecs_service" "agent" {
  count = local.create_agent ? 1 : 0

  name                              = "${var.name_prefix}-agent"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.agent[0].arn
  desired_count                     = var.agent.min_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  enable_execute_command            = var.agent.enable_execute_command
  health_check_grace_period_seconds = var.agent.health_check_grace_period
  availability_zone_rebalancing     = "ENABLED"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.agent_tasks[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.agent[0].arn
    container_name   = "agent"
    container_port   = var.agent.port
  }

  propagate_tags = "SERVICE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent"
  })

  depends_on = [
    aws_lb_listener.agent_http,
    aws_lb_listener.agent_https
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }
}
