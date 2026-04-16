output "state_bucket_name" {
  description = "Nom du bucket S3 pour le state Terraform"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "ARN du bucket S3 pour le state Terraform"
  value       = aws_s3_bucket.terraform_state.arn
}

output "kms_key_arn" {
  description = "ARN de la clé KMS pour le chiffrement du state"
  value       = aws_kms_key.terraform_state.arn
}

output "kms_key_id" {
  description = "ID de la clé KMS pour le chiffrement du state"
  value       = aws_kms_key.terraform_state.key_id
}
