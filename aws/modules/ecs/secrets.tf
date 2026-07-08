resource "random_password" "cookie_secret" {
  count = local.create_brms ? 1 : 0

  length           = 64
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "cookie_secret" {
  count = local.create_brms ? 1 : 0

  name                    = "${var.name_prefix}-brms-cookie-secret"
  description             = "Auto-generated cookie secret for BRMS session management"
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-cookie-secret"
  })
}

resource "aws_secretsmanager_secret_version" "cookie_secret" {
  count = local.create_brms ? 1 : 0

  secret_id     = aws_secretsmanager_secret.cookie_secret[0].id
  secret_string = random_password.cookie_secret[0].result
}

locals {
  use_env_secrets_provider = local.create_brms && var.brms.secrets_provider.type == "env"
  use_kms_secrets_provider = local.create_brms && var.brms.secrets_provider.type == "aws-kms"
  create_kms_key           = local.use_kms_secrets_provider && var.brms.secrets_provider.create_kms_key

  brms_kms_key_id = local.use_kms_secrets_provider ? (
    local.create_kms_key ? aws_kms_key.brms_secrets[0].key_id : var.brms.secrets_provider.kms_key_arn
  ) : null
}

resource "random_password" "secrets_master_key" {
  count = local.use_env_secrets_provider ? 1 : 0

  length           = var.brms.secrets_provider.master_key_length
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "secrets_master_key" {
  count = local.use_env_secrets_provider ? 1 : 0

  name                    = "${var.name_prefix}-brms-secrets-master-key"
  description             = "Auto-generated master key for BRMS secrets encryption (env provider) - DO NOT DELETE"
  recovery_window_in_days = coalesce(var.brms.secrets_provider.master_key_recovery_window_in_days, var.secret_recovery_window_in_days)

  tags = merge(local.common_tags, {
    Name     = "${var.name_prefix}-brms-secrets-master-key"
    Critical = "true"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "secrets_master_key" {
  count = local.use_env_secrets_provider ? 1 : 0

  secret_id     = aws_secretsmanager_secret.secrets_master_key[0].id
  secret_string = random_password.secrets_master_key[0].result
}

resource "aws_kms_key" "brms_secrets" {
  count = local.create_kms_key ? 1 : 0

  description             = "KMS key for BRMS secrets encryption - DO NOT DELETE"
  deletion_window_in_days = var.brms.secrets_provider.kms_deletion_window
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name     = "${var.name_prefix}-brms-secrets-kms"
    Critical = "true"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_kms_alias" "brms_secrets" {
  count = local.create_kms_key && var.brms.secrets_provider.kms_key_alias != null ? 1 : 0

  name          = "alias/${var.brms.secrets_provider.kms_key_alias}"
  target_key_id = aws_kms_key.brms_secrets[0].key_id
}
