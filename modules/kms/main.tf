data "aws_caller_identity" "current" {}

resource "aws_kms_key" "nextcloud" {
  description             = "KMS key for Nextcloud infrastructure (S3, RDS, Secrets, EBS)"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EC2 and RDS services"
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "rds.amazonaws.com",
            "s3.amazonaws.com",
            "secretsmanager.amazonaws.com",
            "logs.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "nextcloud-${var.environment}"
  }
}

resource "aws_kms_alias" "nextcloud" {
  name          = "alias/nextcloud-${var.environment}"
  target_key_id = aws_kms_key.nextcloud.key_id
}
