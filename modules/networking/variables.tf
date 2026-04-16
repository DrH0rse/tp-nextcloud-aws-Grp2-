variable "environment" {
  description = "Environnement"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs des subnets publics (ALB)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs des subnets privés (EC2 + RDS)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Zones de disponibilité"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "flow_logs_retention_days" {
  description = "Rétention des VPC Flow Logs en jours"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "ARN de la clé KMS pour le chiffrement des logs"
  type        = string
}

variable "owner_tag" {
  description = "Tag Owner requis par formation-require-owner-tag"
  type        = string
  default     = ""
}

variable "enable_flow_logs" {
  description = "Activer les VPC Flow Logs (nécessite iam:CreateRole)"
  type        = bool
  default     = false
}
