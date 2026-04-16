terraform {
  backend "s3" {
    # bucket et kms_key_id sont passés via backend.tfvars
    # Usage : terraform init -backend-config=backend.tfvars
    bucket = "REPLACE_WITH_BOOTSTRAP_OUTPUT"
    key    = "envs/dev/terraform.tfstate"
    region = "eu-west-3"

    encrypt      = true
    use_lockfile = true
    # Natif Terraform 1.10 — remplace DynamoDB pour le locking
    # Requiert object_lock_enabled = true sur le bucket (créé par bootstrap)
  }
}
