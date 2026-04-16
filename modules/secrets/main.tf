# ── Mots de passe générés aléatoirement ───────────────────────────────────────
resource "random_password" "db" {
  length           = var.password_length
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "random_password" "nextcloud_admin" {
  length           = var.password_length
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# ── Secret base de données ────────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "db" {
  name        = "${var.project_name}/${var.environment}/db"
  description = "Credentials PostgreSQL pour Nextcloud"
  kms_key_id  = var.kms_key_arn

  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
  })
}

# ── Secret admin Nextcloud ────────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "nextcloud_admin" {
  name        = "${var.project_name}/${var.environment}/admin"
  description = "Credentials administrateur Nextcloud"
  kms_key_id  = var.kms_key_arn

  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-admin-secret"
  }
}

resource "aws_secretsmanager_secret_version" "nextcloud_admin" {
  secret_id = aws_secretsmanager_secret.nextcloud_admin.id
  secret_string = jsonencode({
    username = var.nextcloud_admin_user
    password = random_password.nextcloud_admin.result
  })
}
