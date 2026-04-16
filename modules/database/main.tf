# ── DB Subnet Group ───────────────────────────────────────────────────────────
resource "aws_db_subnet_group" "nextcloud" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Subnet group for Nextcloud RDS PostgreSQL"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# ── Parameter Group (force SSL) ───────────────────────────────────────────────
resource "aws_db_parameter_group" "nextcloud" {
  name        = "${var.project_name}-${var.environment}-pg15"
  family      = "postgres15"
  description = "Parameter group for Nextcloud PostgreSQL 15 (SSL enforced)"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-pg15"
  }
}

# ── RDS PostgreSQL Multi-AZ ───────────────────────────────────────────────────
resource "aws_db_instance" "nextcloud" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.nextcloud.name

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 3
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.nextcloud.name
  vpc_security_group_ids = [var.sg_rds_id]
  publicly_accessible    = false
  multi_az               = true

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot   = true

  # Monitoring (enhanced monitoring désactivé — iam:CreateRole bloqué en formation)
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_arn
  performance_insights_retention_period = 7
  monitoring_interval                   = 0

  # Deletion protection désactivée pour TP
  #tfsec:ignore:aws-rds-enable-deletion-protection
  deletion_protection = false

  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}

# Enhanced Monitoring désactivé (monitoring_interval = 0)
# À réactiver avec un rôle monitoring dédié quand iam:CreateRole sera autorisé
