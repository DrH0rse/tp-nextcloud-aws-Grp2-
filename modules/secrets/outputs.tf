output "db_secret_arn" {
  description = "ARN du secret base de données"
  value       = aws_secretsmanager_secret.db.arn
}

output "db_secret_name" {
  description = "Nom du secret base de données"
  value       = aws_secretsmanager_secret.db.name
}

output "admin_secret_arn" {
  description = "ARN du secret admin Nextcloud"
  value       = aws_secretsmanager_secret.nextcloud_admin.arn
}

output "admin_secret_name" {
  description = "Nom du secret admin Nextcloud"
  value       = aws_secretsmanager_secret.nextcloud_admin.name
}

output "db_password" {
  description = "Mot de passe DB généré (pour passer au module database)"
  value       = random_password.db.result
  sensitive   = true
}
