variable "environment" {
  description = "Environnement"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "domain_name" {
  description = "Nom de domaine pour le certificat (ex: nextcloud.example.com)"
  type        = string
  default     = "nextcloud.internal"
}

variable "cert_validity_hours" {
  description = "Durée de validité du certificat en heures"
  type        = number
  default     = 8760 # 1 an
}
