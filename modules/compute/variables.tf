variable "environment" {
  description = "Environnement"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs des subnets publics pour l'ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs des subnets privés pour l'ASG"
  type        = list(string)
}

variable "sg_alb_id" {
  description = "ID du Security Group ALB"
  type        = string
}

variable "sg_ec2_id" {
  description = "ID du Security Group EC2"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN du certificat ACM pour HTTPS"
  type        = string
}

variable "instance_profile_name" {
  description = "Nom de l'Instance Profile IAM (null pour désactiver)"
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "ARN de la clé KMS pour le chiffrement EBS"
  type        = string
}

variable "alb_logs_bucket_name" {
  description = "Nom du bucket pour les logs ALB"
  type        = string
}

variable "nextcloud_bucket_name" {
  description = "Nom du bucket S3 Nextcloud"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN du secret DB"
  type        = string
}

variable "admin_secret_arn" {
  description = "ARN du secret admin"
  type        = string
}

variable "db_host" {
  description = "Hostname de la base de données RDS"
  type        = string
  default     = "db-placeholder.internal"
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "nextcloud"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "ID de l'AMI Amazon Linux 2023"
  type        = string
}

variable "asg_min_size" {
  description = "Taille minimale de l'ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Taille maximale de l'ASG"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Capacité désirée de l'ASG"
  type        = number
  default     = 1
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-3"
}

variable "owner_tag" {
  description = "Tag Owner requis par la policy formation-require-owner-tag"
  type        = string
  default     = ""
}
