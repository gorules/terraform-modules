resource "aws_iam_user" "s3_access" {
  count = local.use_secrets ? 1 : 0

  name = "${var.name_prefix}-s3-user"

  tags = local.common_tags
}

resource "aws_iam_user_policy_attachment" "s3_access" {
  count = local.use_secrets ? 1 : 0

  user       = aws_iam_user.s3_access[0].name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_access_key" "s3_access" {
  count = local.use_secrets ? 1 : 0

  user = aws_iam_user.s3_access[0].name
}

resource "aws_secretsmanager_secret" "s3_credentials" {
  count = local.use_secrets ? 1 : 0

  name        = "${var.name_prefix}-s3-credentials"
  description = "S3 access credentials for GoRules"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "s3_credentials" {
  count = local.use_secrets ? 1 : 0

  secret_id = aws_secretsmanager_secret.s3_credentials[0].id

  secret_string = jsonencode({
    access_key_id     = aws_iam_access_key.s3_access[0].id
    secret_access_key = aws_iam_access_key.s3_access[0].secret
    bucket_name       = local.bucket_name
    region            = data.aws_region.current.region
  })
}
