# ── Module KMS ────────────────────────────────────────────────────────────────
module "kms" {
  source = "../../modules/kms"

  project_name = var.project_name
  environment  = var.environment
}

# ── Module Networking ─────────────────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  kms_key_arn          = module.kms.key_arn
  owner_tag            = "etudiant32"

  depends_on = [module.kms]
}

# ── Module Storage ────────────────────────────────────────────────────────────
module "storage" {
  source = "../../modules/storage"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms.key_arn

  depends_on = [module.kms]
}

# ── Module Secrets ────────────────────────────────────────────────────────────
module "secrets" {
  source = "../../modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms.key_arn
  db_username  = var.db_username

  depends_on = [module.kms]
}

# ── Module Database ───────────────────────────────────────────────────────────
module "database" {
  source = "../../modules/database"

  project_name       = var.project_name
  environment        = var.environment
  kms_key_arn        = module.kms.key_arn
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  sg_rds_id          = module.networking.sg_rds_id
  db_secret_arn      = module.secrets.db_secret_arn
  db_username        = var.db_username
  db_password        = module.secrets.db_password
  db_name            = var.db_name
  instance_class     = var.db_instance_class

  depends_on = [module.networking, module.secrets]
}

# ── Module IAM ────────────────────────────────────────────────────────────────
module "iam" {
  source = "../../modules/iam"

  providers = {
    aws         = aws
    aws.no_tags = aws.no_tags
  }

  project_name         = var.project_name
  environment          = var.environment
  nextcloud_bucket_arn = module.storage.nextcloud_bucket_arn
  db_secret_arn        = module.secrets.db_secret_arn
  admin_secret_arn     = module.secrets.admin_secret_arn
  kms_key_arn          = module.kms.key_arn
  create_iam_resources     = true
  iam_permissions_boundary = "arn:aws:iam::039497794217:policy/formation-permissions-boundary-paris"

  depends_on = [module.storage, module.secrets, module.kms]
}

# ── Module Certificates ───────────────────────────────────────────────────────
module "certificates" {
  source = "../../modules/certificates"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
}

# ── Module Compute ────────────────────────────────────────────────────────────
module "compute" {
  source = "../../modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  sg_alb_id             = module.networking.sg_alb_id
  sg_ec2_id             = module.networking.sg_ec2_id
  acm_certificate_arn   = module.certificates.acm_certificate_arn
  instance_profile_name = module.iam.instance_profile_name
  kms_key_arn           = module.kms.key_arn
  alb_logs_bucket_name  = module.storage.alb_logs_bucket_name
  nextcloud_bucket_name = module.storage.nextcloud_bucket_name
  db_secret_arn         = module.secrets.db_secret_arn
  admin_secret_arn      = module.secrets.admin_secret_arn
  db_host               = var.db_host_override != "" ? var.db_host_override : "db-not-deployed.internal"
  owner_tag             = "etudiant32"
  db_name               = var.db_name
  instance_type         = var.ec2_instance_type
  ami_id                = var.ami_id
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
  create_asg            = false

  depends_on = [
    module.networking,
    module.storage,
    module.iam,
    module.certificates
  ]
}
