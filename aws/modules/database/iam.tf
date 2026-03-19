data "aws_caller_identity" "current" {
  count = var.auth == "iam" ? 1 : 0
}

data "aws_region" "current" {
  count = var.auth == "iam" ? 1 : 0
}

data "aws_iam_policy_document" "rds_iam_connect" {
  count = var.auth == "iam" ? 1 : 0

  statement {
    sid       = "AllowRDSIAMConnect"
    effect    = "Allow"
    actions   = ["rds-db:connect"]
    resources = ["arn:aws:rds-db:${data.aws_region.current[0].id}:${data.aws_caller_identity.current[0].account_id}:dbuser:${aws_rds_cluster.this.cluster_resource_id}/${var.iam_username}"]
  }
}

resource "aws_iam_policy" "rds_iam_connect" {
  count = var.auth == "iam" ? 1 : 0

  name        = "${var.name_prefix}-rds-iam-connect"
  description = "Policy for IAM database authentication to Aurora cluster"
  policy      = data.aws_iam_policy_document.rds_iam_connect[0].json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-iam-connect"
  })
}
