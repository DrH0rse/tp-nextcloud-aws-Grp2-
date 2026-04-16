terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.no_tags]
    }
  }
}

# ── IAM Role EC2 ──────────────────────────────────────────────────────────────
# create_iam_resources = false si iam:CreateRole est bloqué (ex: env formation)
resource "aws_iam_role" "nextcloud_ec2" {
  count = var.create_iam_resources ? 1 : 0

  name        = "${var.project_name}-${var.environment}-ec2-role"
  description = "IAM Role for Nextcloud EC2 instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  permissions_boundary = var.iam_permissions_boundary != "" ? var.iam_permissions_boundary : null

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}

# ── Policies inline (permissions minimales) ───────────────────────────────────

resource "aws_iam_role_policy" "s3_nextcloud" {
  count = var.create_iam_resources ? 1 : 0

  name = "s3-nextcloud-data"
  role = aws_iam_role.nextcloud_ec2[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowNextcloudBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          var.nextcloud_bucket_arn,
          "${var.nextcloud_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "secrets_manager" {
  count = var.create_iam_resources ? 1 : 0

  name = "secrets-manager-read"
  role = aws_iam_role.nextcloud_ec2[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          var.db_secret_arn,
          var.admin_secret_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "kms_decrypt" {
  count = var.create_iam_resources ? 1 : 0

  name = "kms-decrypt"
  role = aws_iam_role.nextcloud_ec2[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = [var.kms_key_arn]
      }
    ]
  })
}

# CloudWatch Logs : écriture des logs Docker
# tfsec:ignore — wildcards région/compte nécessaires dans un module réutilisable
#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "cloudwatch_logs" {
  count = var.create_iam_resources ? 1 : 0

  name = "cloudwatch-logs"
  role = aws_iam_role.nextcloud_ec2[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowCreateLogGroup"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup"]
        Resource = "arn:aws:logs:*:*:log-group:/nextcloud/docker"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/nextcloud/docker:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.create_iam_resources ? 1 : 0

  role       = aws_iam_role.nextcloud_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ── Instance Profile ───────────────────────────────────────────────────────────
resource "aws_iam_instance_profile" "nextcloud" {
  count    = var.create_iam_resources ? 1 : 0
  provider = aws.no_tags

  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.nextcloud_ec2[0].name
}
