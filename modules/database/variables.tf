variable "environment" {
  description = "Environnement"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de la clé KMS pour le chiffrement RDS"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs des subnets privés pour RDS"
  type        = list(string)
}

variable "sg_rds_id" {
  description = "ID du Security Group RDS"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN du secret contenant les credentials DB"
  type        = string
}

variable "enable_enhanced_monitoring" {
  description = "Activer le Enhanced Monitoring RDS (nécessite iam:CreateRole)"
  type        = bool
  default     = false
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  default     = "nextcloud"
}

variable "db_password" {
  description = "Mot de passe de la base de données (depuis Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "nextcloud"
}

variable "instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Stockage alloué en GB"
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "Version de PostgreSQL"
  type        = string
  default     = "15"
}
