locals {
  create_lambda = var.auth == "iam"
}

resource "aws_security_group" "lambda" {
  count = local.create_lambda ? 1 : 0

  name        = "${var.name_prefix}-iam-user-setup-lambda-sg"
  description = "Security group for IAM user setup Lambda function"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-iam-user-setup-lambda-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "lambda_to_aurora" {
  count = local.create_lambda ? 1 : 0

  type                     = "egress"
  description              = "Allow Lambda to connect to Aurora PostgreSQL"
  from_port                = local.port
  to_port                  = local.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda[0].id
  source_security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "lambda_https_egress" {
  count = local.create_lambda ? 1 : 0

  type              = "egress"
  description       = "Allow Lambda to access AWS services via HTTPS"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda[0].id
}

resource "aws_security_group_rule" "aurora_from_lambda" {
  count = local.create_lambda ? 1 : 0

  type                     = "ingress"
  description              = "Allow Lambda to connect for IAM user setup"
  from_port                = local.port
  to_port                  = local.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = aws_security_group.lambda[0].id
}

data "aws_iam_policy_document" "lambda_assume_role" {
  count = local.create_lambda ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  count = local.create_lambda ? 1 : 0

  name               = "${var.name_prefix}-iam-user-setup-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-iam-user-setup-lambda"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  count = local.create_lambda ? 1 : 0

  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "lambda_secrets_access" {
  count = local.create_lambda ? 1 : 0

  statement {
    sid     = "ReadDatabaseCredentials"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.credentials.arn
    ]
  }
}

resource "aws_iam_policy" "lambda_secrets_access" {
  count = local.create_lambda ? 1 : 0

  name        = "${var.name_prefix}-iam-user-setup-secrets"
  description = "Allow Lambda to read database credentials for IAM user setup"
  policy      = data.aws_iam_policy_document.lambda_secrets_access[0].json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-iam-user-setup-secrets"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_access" {
  count = local.create_lambda ? 1 : 0

  role       = aws_iam_role.lambda[0].name
  policy_arn = aws_iam_policy.lambda_secrets_access[0].arn
}

resource "aws_lambda_layer_version" "psycopg" {
  count = local.create_lambda ? 1 : 0

  filename            = "${path.module}/layers/psycopg_layer.zip"
  layer_name          = "${var.name_prefix}-psycopg"
  source_code_hash    = filebase64sha256("${path.module}/layers/psycopg_layer.zip")
  compatible_runtimes = ["python3.14"]

  description = "psycopg PostgreSQL adapter for Python"
}

data "archive_file" "lambda" {
  count = local.create_lambda ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/lambda/iam_user_setup.py"
  output_path = "${path.module}/lambda/iam_user_setup.zip"
}

resource "aws_lambda_function" "iam_user_setup" {
  count = local.create_lambda ? 1 : 0

  function_name = "${var.name_prefix}-iam-user-setup"
  description   = "Creates PostgreSQL users for IAM database authentication"
  role          = aws_iam_role.lambda[0].arn
  handler       = "iam_user_setup.handler"
  runtime       = "python3.14"
  timeout       = 120
  memory_size   = 256

  filename         = data.archive_file.lambda[0].output_path
  source_code_hash = data.archive_file.lambda[0].output_base64sha256

  layers = [aws_lambda_layer_version.psycopg[0].arn]

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda[0].id]
  }

  environment {
    variables = {
      DB_SECRET_ARN = aws_secretsmanager_secret.credentials.arn
      DB_HOST       = aws_rds_cluster.this.endpoint
      DB_PORT       = tostring(local.port)
      DB_NAME       = var.database_name
      DB_USER       = var.iam_username
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-iam-user-setup"
  })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_iam_role_policy_attachment.lambda_secrets_access,
    aws_rds_cluster_instance.this
  ]
}

resource "aws_cloudwatch_log_group" "lambda" {
  count = local.create_lambda ? 1 : 0

  name              = "/aws/lambda/${var.name_prefix}-iam-user-setup"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-iam-user-setup-logs"
  })
}

resource "aws_lambda_invocation" "create_iam_user" {
  count = local.create_lambda ? 1 : 0

  function_name = aws_lambda_function.iam_user_setup[0].function_name

  input = jsonencode({})

  depends_on = [
    aws_lambda_function.iam_user_setup,
    aws_security_group_rule.aurora_from_lambda,
    aws_cloudwatch_log_group.lambda
  ]

  lifecycle {
    replace_triggered_by = [
      aws_lambda_function.iam_user_setup[0]
    ]
  }
}
