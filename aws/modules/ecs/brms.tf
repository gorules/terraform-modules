resource "aws_cloudwatch_log_group" "brms" {
  count = local.create_brms ? 1 : 0

  name              = "/ecs/${var.name_prefix}/brms"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-logs"
  })
}

resource "aws_lb" "brms" {
  count = local.create_brms ? 1 : 0

  name               = "${var.name_prefix}-brms-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.brms_alb[0].id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.brms.alb_deletion_protection

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-alb"
  })
}

resource "aws_lb_target_group" "brms" {
  count = local.create_brms ? 1 : 0

  name                 = "${var.name_prefix}-brms-tg"
  port                 = var.brms.port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = var.brms.deregistration_delay

  health_check {
    enabled             = true
    path                = var.brms.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "brms_http" {
  count = local.create_brms ? 1 : 0

  load_balancer_arn = aws_lb.brms[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "brms_https" {
  count = local.create_brms ? 1 : 0

  load_balancer_arn = aws_lb.brms[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.brms_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.brms[0].arn
  }

  depends_on = [aws_acm_certificate_validation.brms]
}

locals {
  brms_app_url = var.brms != null ? "https://${var.brms.domain}" : null

  brms_storage_env = var.brms != null && var.storage != null ? [
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

  brms_base_env = var.brms != null ? concat([
    {
      name  = "DB_HOST"
      value = var.database.endpoint
    },
    {
      name  = "DB_PORT"
      value = tostring(var.database.port)
    },
    {
      name  = "DB_USER"
      value = var.database.username
    },
    {
      name  = "DB_NAME"
      value = var.database.name
    },
    {
      name  = "APP_URL"
      value = local.brms_app_url
    }
  ], local.brms_storage_env) : []

  brms_ssl_env = var.brms != null && var.database != null ? (
    var.database.ssl_verify ? [
      {
        name  = "DB_SSL_CA"
        value = local.rds_ca_cert_base64
      }
      ] : [
      {
        name  = "DB_REJECT_UNAUTHORIZED"
        value = "false"
      }
    ]
  ) : []

  brms_environment = var.brms != null ? concat(
    local.brms_base_env,
    local.brms_ssl_env,
    local.brms_iam_auth_env,
    local.brms_secrets_provider_env,
    local.brms_kms_env,
    local.brms_ai_env,
    var.brms.env
  ) : []

  brms_base_secrets = var.brms != null ? [
    {
      name      = "LICENSE_KEY"
      valueFrom = var.brms.license_key_secret_arn
    },
    {
      name      = "COOKIE_SECRET"
      valueFrom = aws_secretsmanager_secret.cookie_secret[0].arn
    }
  ] : []

  brms_db_password_secret = var.brms != null && var.database != null && var.database.auth == "secrets" ? [
    {
      name      = "DB_PASSWORD"
      valueFrom = "${var.database.credentials_secret_arn}:password::"
    }
  ] : []

  brms_iam_auth_env = var.brms != null && var.database != null && var.database.auth == "iam" ? [
    {
      name  = "DB_CREDENTIALS_PROVIDER"
      value = "aws-iam"
    }
  ] : []

  brms_secrets_provider_env = var.brms != null ? [
    { name = "SECRETS_PROVIDER", value = var.brms.secrets_provider.type == "env" ? "env" : "aws-kms" }
  ] : []

  brms_kms_env = var.brms != null && var.brms.secrets_provider.type == "aws-kms" ? [
    { name = "SECRETS_AWS_KMS_KEY_ID", value = local.brms_kms_key_id }
  ] : []

  brms_ai_env = var.brms != null && var.brms.ai != null ? concat(
    [
      { name = "LLM_PROVIDER", value = var.brms.ai.provider },
      { name = "LLM_MODEL", value = var.brms.ai.model },
      { name = "LLM_TEMPERATURE", value = tostring(var.brms.ai.temperature) },
      { name = "LLM_MAX_OUTPUT_TOKENS", value = tostring(var.brms.ai.max_output_tokens) },
      { name = "LLM_THINKING_LEVEL", value = var.brms.ai.thinking_level },
    ],
    var.brms.ai.context_window != null ? [
      { name = "LLM_CONTEXT_WINDOW", value = tostring(var.brms.ai.context_window) }
    ] : [],
    var.brms.ai.provider == "azure-openai" ? [
      { name = "LLM_AZURE_RESOURCE_NAME", value = var.brms.ai.azure_resource_name }
    ] : []
  ) : []

  brms_ai_secrets = var.brms != null && var.brms.ai != null && var.brms.ai.api_key_secret_arn != null ? [
    { name = "LLM_API_KEY", valueFrom = var.brms.ai.api_key_secret_arn }
  ] : []

  brms_secrets_provider_secrets = local.use_env_secrets_provider ? [
    { name = "SECRETS_MASTER_KEY", valueFrom = aws_secretsmanager_secret.secrets_master_key[0].arn }
  ] : []

  brms_secrets = var.brms != null ? concat(
    local.brms_base_secrets,
    local.brms_db_password_secret,
    local.brms_secrets_provider_secrets,
    local.brms_ai_secrets,
    var.brms.secrets
  ) : []
}

resource "aws_ecs_task_definition" "brms" {
  count = local.create_brms ? 1 : 0

  family                   = "${var.name_prefix}-brms"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.brms.cpu
  memory                   = var.brms.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.brms_task[0].arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "brms"
      image     = var.brms.image
      essential = true

      portMappings = [
        {
          containerPort = var.brms.port
          hostPort      = var.brms.port
          protocol      = "tcp"
        }
      ]

      environment = local.brms_environment
      secrets     = local.brms_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.brms[0].name
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "brms"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms"
  })
}

resource "aws_ecs_service" "brms" {
  count = local.create_brms ? 1 : 0

  name                              = "${var.name_prefix}-brms"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.brms[0].arn
  desired_count                     = var.brms.min_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  enable_execute_command            = var.brms.enable_execute_command
  health_check_grace_period_seconds = var.brms.health_check_grace_period
  availability_zone_rebalancing     = "ENABLED"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.brms_tasks[0].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.brms[0].arn
    container_name   = "brms"
    container_port   = var.brms.port
  }

  propagate_tags = "SERVICE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms"
  })

  depends_on = [
    aws_lb_listener.brms_http,
    aws_lb_listener.brms_https
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }
}
