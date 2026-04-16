variable "environment" {
  description = "Environnement"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "nextcloud_bucket_arn" {
  description = "ARN du bucket S3 Nextcloud data"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN du secret DB dans Secrets Manager"
  type        = string
}

variable "admin_secret_arn" {
  description = "ARN du secret admin dans Secrets Manager"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de la clé KMS"
  type        = string
}

variable "create_iam_resources" {
  description = "Créer les ressources IAM (false si iam:CreateRole est bloqué)"
  type        = bool
  default     = true
}

variable "iam_permissions_boundary" {
  description = "ARN de la permissions boundary à attacher au rôle EC2 (requis sur compte formation)"
  type        = string
  default     = ""
}
