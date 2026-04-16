data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── Bucket ALB Logs ───────────────────────────────────────────────────────────
# (créé en premier pour être référencé dans le logging du bucket nextcloud)
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-${var.environment}-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${var.project_name}-${var.environment}-alb-logs"
    Purpose = "alb-access-logs"
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ALB logs ne supporte pas SSE-KMS — AES256 requis par AWS ELB service
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle pour expirer les logs après 90 jours
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "expire-alb-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.alb_logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Policy ALB : autoriser le service ALB (compte ELB eu-west-3 : 009996457667)
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowELBLogs"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::009996457667:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid    = "DenyNonTLS"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:*"
        Resource = [
          aws_s3_bucket.alb_logs.arn,
          "${aws_s3_bucket.alb_logs.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.alb_logs]
}

# ── Bucket Nextcloud Data ─────────────────────────────────────────────────────
resource "aws_s3_bucket" "nextcloud_data" {
  bucket = "${var.project_name}-${var.environment}-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${var.project_name}-${var.environment}-data"
    Purpose = "nextcloud-object-storage"
  }
}

resource "aws_s3_bucket_versioning" "nextcloud_data" {
  bucket = aws_s3_bucket.nextcloud_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "nextcloud_data" {
  bucket = aws_s3_bucket.nextcloud_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "nextcloud_data" {
  bucket = aws_s3_bucket.nextcloud_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Logging nextcloud_data → alb_logs bucket (tfsec aws-s3-enable-bucket-logging)
resource "aws_s3_bucket_logging" "nextcloud_data" {
  bucket        = aws_s3_bucket.nextcloud_data.id
  target_bucket = aws_s3_bucket.alb_logs.id
  target_prefix = "s3-access-logs/nextcloud-data/"
}

resource "aws_s3_bucket_policy" "nextcloud_data_tls" {
  bucket = aws_s3_bucket.nextcloud_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.nextcloud_data.arn,
          "${aws_s3_bucket.nextcloud_data.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.nextcloud_data]
}
