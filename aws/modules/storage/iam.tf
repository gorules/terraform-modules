data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_policy" "s3_access" {
  name        = "${var.name_prefix}-s3-access"
  description = "IAM policy for S3 bucket access for GoRules"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = local.bucket_arn
      },
      {
        Sid    = "ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:DeleteObjectVersion"
        ]
        Resource = "${local.bucket_arn}/*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "s3_read_only" {
  name        = "${var.name_prefix}-s3-read-only"
  description = "IAM policy for read-only S3 bucket access for GoRules Agent"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = local.bucket_arn
      },
      {
        Sid    = "ReadObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${local.bucket_arn}/*"
      }
    ]
  })

  tags = local.common_tags
}
