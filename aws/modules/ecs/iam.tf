data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    sid    = "AllowECSTaskExecution"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.name_prefix}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-ecs-execution"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "secrets_read" {
  dynamic "statement" {
    for_each = local.create_brms ? [1] : []
    content {
      sid    = "ReadBRMSSecrets"
      effect = "Allow"

      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]

      resources = concat(
        [
          var.brms.license_key_secret_arn,
          aws_secretsmanager_secret.cookie_secret[0].arn
        ],
        local.use_env_secrets_provider ? [aws_secretsmanager_secret.secrets_master_key[0].arn] : [],
        var.brms.ai != null && var.brms.ai.api_key_secret_arn != null ? [var.brms.ai.api_key_secret_arn] : [],
        [for s in var.brms.secrets : s.valueFrom]
      )
    }
  }

  dynamic "statement" {
    for_each = local.create_agent && length(var.agent.secrets) > 0 ? [1] : []
    content {
      sid    = "ReadAgentSecrets"
      effect = "Allow"

      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]

      resources = [for s in var.agent.secrets : s.valueFrom]
    }
  }

  dynamic "statement" {
    for_each = local.create_brms && var.database != null && var.database.auth == "secrets" ? [1] : []
    content {
      sid    = "ReadDatabaseCredentials"
      effect = "Allow"

      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]

      resources = [var.database.credentials_secret_arn]
    }
  }
}

resource "aws_iam_policy" "secrets_read" {
  count = local.create_brms || (local.create_agent && length(var.agent.secrets) > 0) ? 1 : 0

  name        = "${var.name_prefix}-ecs-secrets-read"
  description = "Policy for ECS tasks to read secrets from Secrets Manager"
  policy      = data.aws_iam_policy_document.secrets_read.json

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-ecs-secrets-read"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_secrets" {
  count = local.create_brms || (local.create_agent && length(var.agent.secrets) > 0) ? 1 : 0

  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.secrets_read[0].arn
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    sid    = "AllowECSTaskAssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "brms_task" {
  count = local.create_brms ? 1 : 0

  name               = "${var.name_prefix}-brms-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-task"
  })
}

resource "aws_iam_role_policy_attachment" "brms_s3_access" {
  count = local.create_brms && var.storage != null ? 1 : 0

  role       = aws_iam_role.brms_task[0].name
  policy_arn = var.storage.iam_policy_arn
}

resource "aws_iam_role" "agent_task" {
  count = local.create_agent ? 1 : 0

  name               = "${var.name_prefix}-agent-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-task"
  })
}

resource "aws_iam_role_policy_attachment" "agent_s3_read_only" {
  count = local.create_agent && var.storage != null ? 1 : 0

  role       = aws_iam_role.agent_task[0].name
  policy_arn = var.storage.iam_read_only_policy_arn
}

data "aws_iam_policy_document" "ecs_exec" {
  statement {
    sid    = "AllowECSExec"
    effect = "Allow"

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_exec" {
  count = (local.create_brms && var.brms.enable_execute_command) || (local.create_agent && var.agent.enable_execute_command) ? 1 : 0

  name        = "${var.name_prefix}-ecs-exec"
  description = "Policy for ECS Exec to allow container access via SSM"
  policy      = data.aws_iam_policy_document.ecs_exec.json

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-ecs-exec"
  })
}

resource "aws_iam_role_policy_attachment" "brms_ecs_exec" {
  count = local.create_brms && var.brms.enable_execute_command ? 1 : 0

  role       = aws_iam_role.brms_task[0].name
  policy_arn = aws_iam_policy.ecs_exec[0].arn
}

resource "aws_iam_role_policy_attachment" "agent_ecs_exec" {
  count = local.create_agent && var.agent.enable_execute_command ? 1 : 0

  role       = aws_iam_role.agent_task[0].name
  policy_arn = aws_iam_policy.ecs_exec[0].arn
}

resource "aws_iam_role_policy_attachment" "brms_rds_iam_connect" {
  count = local.create_brms && var.database != null && var.database.auth == "iam" ? 1 : 0

  role       = aws_iam_role.brms_task[0].name
  policy_arn = var.database.rds_iam_connect_policy_arn
}

data "aws_iam_policy_document" "brms_kms_access" {
  count = local.use_kms_secrets_provider ? 1 : 0

  statement {
    sid    = "AllowKMSForSecretsProvider"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey"
    ]

    resources = [
      local.create_kms_key ? aws_kms_key.brms_secrets[0].arn : var.brms.secrets_provider.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "brms_kms_access" {
  count = local.use_kms_secrets_provider ? 1 : 0

  name        = "${var.name_prefix}-brms-kms-access"
  description = "Policy for BRMS to access KMS key for secrets encryption"
  policy      = data.aws_iam_policy_document.brms_kms_access[0].json

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-kms-access"
  })
}

resource "aws_iam_role_policy_attachment" "brms_kms_access" {
  count = local.use_kms_secrets_provider ? 1 : 0

  role       = aws_iam_role.brms_task[0].name
  policy_arn = aws_iam_policy.brms_kms_access[0].arn
}

data "aws_iam_policy_document" "brms_external_buckets" {
  count = local.create_brms && length(var.brms_external_buckets) > 0 ? 1 : 0

  statement {
    sid    = "ListExternalBuckets"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [for b in var.brms_external_buckets : b.arn]
  }

  statement {
    sid    = "ExternalBucketObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion"
    ]
    resources = [for b in var.brms_external_buckets : "${b.arn}/*"]
  }
}

resource "aws_iam_policy" "brms_external_buckets" {
  count = local.create_brms && length(var.brms_external_buckets) > 0 ? 1 : 0

  name        = "${var.name_prefix}-brms-external-buckets"
  description = "IAM policy for BRMS to access external S3 buckets (cross-account)"
  policy      = data.aws_iam_policy_document.brms_external_buckets[0].json

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-external-buckets"
  })
}

resource "aws_iam_role_policy_attachment" "brms_external_buckets" {
  count = local.create_brms && length(var.brms_external_buckets) > 0 ? 1 : 0

  role       = aws_iam_role.brms_task[0].name
  policy_arn = aws_iam_policy.brms_external_buckets[0].arn
}

locals {
  # Inference profile prefixes: us., eu., apac., global., au., ca., jp., us-gov.
  bedrock_model_id             = var.brms != null && var.brms.ai != null ? var.brms.ai.model : ""
  bedrock_is_inference_profile = can(regex("^(us|eu|apac|global|au|ca|jp|us-gov)\\.", local.bedrock_model_id))
  bedrock_base_model_id        = local.bedrock_is_inference_profile ? regex("^[^.]+\\.(.*)", local.bedrock_model_id)[0] : local.bedrock_model_id
}

data "aws_iam_policy_document" "brms_bedrock_access" {
  count = local.create_brms && var.brms.ai != null && var.brms.ai.provider == "amazon-bedrock" ? 1 : 0

  # Grant access to the foundation model (needed for both direct and inference profile invocation)
  # Use wildcard region because cross-region inference profiles can route to any region in the geography
  statement {
    sid    = "AllowBedrockFoundationModel"
    effect = "Allow"

    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]

    resources = [
      "arn:aws:bedrock:*::foundation-model/${local.bedrock_base_model_id}"
    ]
  }

  # Grant access to the inference profile when using one (geographic prefix in model ID)
  # Use wildcard region because the profile may resolve to any region within the geography
  dynamic "statement" {
    for_each = local.bedrock_is_inference_profile ? [1] : []
    content {
      sid    = "AllowBedrockInferenceProfile"
      effect = "Allow"

      actions = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ]

      resources = [
        "arn:aws:bedrock:*:${local.account_id}:inference-profile/${local.bedrock_model_id}"
      ]
    }
  }
}

resource "aws_iam_policy" "brms_bedrock_access" {
  count = local.create_brms && var.brms.ai != null && var.brms.ai.provider == "amazon-bedrock" ? 1 : 0

  name        = "${var.name_prefix}-brms-bedrock-access"
  description = "Policy for BRMS to invoke Bedrock foundation models for AI assistant"
  policy      = data.aws_iam_policy_document.brms_bedrock_access[0].json

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-bedrock-access"
  })
}

resource "aws_iam_role_policy_attachment" "brms_bedrock_access" {
  count = local.create_brms && var.brms.ai != null && var.brms.ai.provider == "amazon-bedrock" ? 1 : 0

  role       = aws_iam_role.brms_task[0].name
  policy_arn = aws_iam_policy.brms_bedrock_access[0].arn
}
