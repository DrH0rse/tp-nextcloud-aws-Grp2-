output "key_arn" {
  description = "ARN de la clé KMS"
  value       = aws_kms_key.nextcloud.arn
}

output "key_id" {
  description = "ID de la clé KMS"
  value       = aws_kms_key.nextcloud.key_id
}

output "alias_arn" {
  description = "ARN de l'alias KMS"
  value       = aws_kms_alias.nextcloud.arn
}
