# Nextcloud on AWS — Infrastructure Terraform

Infrastructure Nextcloud production-ready déployée sur AWS eu-west-3 avec Terraform.

## Architecture

- **Réseau** : VPC 10.0.0.0/16, 2 AZ (eu-west-3a/3b), subnets publics (ALB) + privés (EC2, RDS)
- **Calcul** : Auto Scaling Group (min=1, max=2) derrière ALB HTTPS
- **Base de données** : RDS PostgreSQL 15 Multi-AZ, chiffré KMS
- **Stockage** : S3 nextcloud-data (KMS, versioning, TLS)
- **Sécurité** : IAM Instance Profile, Secrets Manager, IMDSv2, VPC Endpoints
- **TLS** : Certificat self-signed importé dans ACM

## Pré-requis

- Terraform >= 1.10
- AWS CLI configuré (profil ou variables d'environnement)
- tfsec (optionnel, pour les checks locaux)

## Déploiement

### Phase 1 — Bootstrap (une seule fois)

```bash
cd ~/nextcloud-aws/bootstrap/
terraform init
terraform apply
# Noter les outputs : state_bucket_name, kms_key_arn
```

### Phase 2 — Environnement dev

```bash
cd ~/nextcloud-aws/envs/dev/
cp backend.tfvars.example backend.tfvars
# Éditer backend.tfvars avec les outputs du bootstrap
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars selon vos besoins

terraform init -backend-config=backend.tfvars
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Modules

| Module | Description |
|--------|-------------|
| `kms` | Clé KMS CMK avec rotation automatique |
| `networking` | VPC, subnets, SGs, VPC Endpoints, Flow Logs |
| `storage` | S3 nextcloud-data + S3 alb-logs |
| `secrets` | Secrets Manager DB + admin Nextcloud |
| `database` | RDS PostgreSQL 15 Multi-AZ |
| `iam` | IAM Role EC2 + Instance Profile |
| `certificates` | Certificat TLS self-signed importé ACM |
| `compute` | ALB + Launch Template (IMDSv2) + ASG |

## Sécurité (tfsec 0 HIGH/CRITICAL)

- IMDSv2 obligatoire sur les instances
- Chiffrement KMS CMK sur EBS, S3, RDS, Secrets
- Security Groups restrictifs (pas de 0.0.0.0/0 en egress)
- VPC Flow Logs activés
- ALB : drop_invalid_header_fields = true
- State Terraform chiffré KMS + object lock

## Bonus — CI/CD

Pipeline GitHub Actions (`.github/workflows/terraform-plan.yml`) :
- OIDC AWS (pas de clés statiques)
- tfsec → terraform validate → plan → commentaire PR
