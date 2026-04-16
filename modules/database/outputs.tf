output "db_endpoint" {
  description = "Endpoint de la base de données RDS"
  value       = aws_db_instance.nextcloud.endpoint
}

output "db_address" {
  description = "Adresse hostname de la base de données RDS"
  value       = aws_db_instance.nextcloud.address
}

output "db_port" {
  description = "Port de la base de données RDS"
  value       = aws_db_instance.nextcloud.port
}

output "db_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.nextcloud.db_name
}

output "db_identifier" {
  description = "Identifiant de l'instance RDS"
  value       = aws_db_instance.nextcloud.identifier
}
