variable "environment" {
  description = "Environnement"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de la clé KMS pour le chiffrement S3"
  type        = string
}

variable "alb_logs_retention_days" {
  description = "Rétention des logs ALB en jours"
  type        = number
  default     = 90
}
