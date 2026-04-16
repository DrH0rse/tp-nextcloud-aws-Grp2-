variable "environment" {
  description = "Environnement"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de la clé KMS pour le chiffrement des secrets"
  type        = string
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  default     = "nextcloud"
}

variable "nextcloud_admin_user" {
  description = "Nom d'utilisateur administrateur Nextcloud"
  type        = string
  default     = "admin"
}

variable "password_length" {
  description = "Longueur des mots de passe générés"
  type        = number
  default     = 32
}
