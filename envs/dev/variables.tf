variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "nextcloud"
}

variable "environment" {
  description = "Environnement"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs des subnets publics"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs des subnets privés"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Zones de disponibilité"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "db_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "nextcloud"
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  default     = "nextcloud"
}

variable "domain_name" {
  description = "Nom de domaine pour le certificat TLS"
  type        = string
  default     = "nextcloud.internal"
}

variable "ec2_instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "ID AMI Amazon Linux 2023 en eu-west-3"
  type        = string
  # Valeur par défaut : Amazon Linux 2023 eu-west-3 (à jour en avril 2026)
  default = "ami-0c7191dc6b3e08b56"
}

variable "asg_min_size" {
  description = "Taille minimale ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Taille maximale ASG"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Capacité désirée ASG"
  type        = number
  default     = 1
}

variable "db_host_override" {
  description = "Override du hostname DB (vide = DB non déployée)"
  type        = string
  default     = ""
}
