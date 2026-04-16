output "alb_dns_name" {
  description = "DNS de l'Application Load Balancer (accès Nextcloud)"
  value       = module.compute.alb_dns_name
}

output "alb_url" {
  description = "URL HTTPS pour accéder à Nextcloud"
  value       = "https://${module.compute.alb_dns_name}"
}

output "db_endpoint" {
  description = "Endpoint de la base de données RDS"
  value       = module.database.db_endpoint
}

output "nextcloud_bucket" {
  description = "Nom du bucket S3 Nextcloud"
  value       = module.storage.nextcloud_bucket_name
}

output "kms_key_arn" {
  description = "ARN de la clé KMS"
  value       = module.kms.key_arn
}

output "db_secret_arn" {
  description = "ARN du secret DB dans Secrets Manager"
  value       = module.secrets.db_secret_arn
}

output "admin_secret_arn" {
  description = "ARN du secret admin dans Secrets Manager"
  value       = module.secrets.admin_secret_arn
}

output "cloudwatch_log_group" {
  description = "Log group CloudWatch pour les containers Docker"
  value       = module.compute.cloudwatch_log_group
}

output "vpc_id" {
  description = "ID du VPC"
  value       = module.networking.vpc_id
}
