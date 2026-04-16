# Ce qui a été fait — Nextcloud AWS Terraform

## Vue d'ensemble

Infrastructure Nextcloud production-ready sur AWS eu-west-3, entièrement codée en Terraform.
**40 fichiers créés**, `terraform validate` ✅, `tfsec HIGH/CRITICAL = 0` ✅

**Nextcloud est-il en ligne ?** Non. L'ALB est déployé et actif mais le Target Group est vide — aucune instance EC2 derrière (ASG et RDS bloqués par les restrictions du compte formation).

---

## Résultat du déploiement (compte etudiant32)

### Ressources déployées ✅ — 64 ressources dans le state

| Module | Ressources AWS créées |
|--------|----------------------|
| **bootstrap** | KMS `alias/nextcloud-terraform-state` + S3 state bucket (object lock) |
| **kms** | KMS CMK `alias/nextcloud-dev` (rotation activée) |
| **networking** | VPC 10.0.0.0/16, 4 subnets (2 publics / 2 privés), IGW, NAT Gateway, 2 route tables, 3 Security Groups + toutes les règles, VPC Endpoint S3 (Gateway) + Secrets Manager (Interface) |
| **storage** | S3 `nextcloud-dev-data-039497794217` (KMS, versioning, force-TLS) + S3 `nextcloud-dev-alb-logs-039497794217` (lifecycle 90j) |
| **secrets** | Secrets Manager `nextcloud/dev/db` + `nextcloud/dev/admin` (passwords aléatoires 32 chars, chiffrés KMS) |
| **certificates** | TLS private key RSA 2048 + self-signed cert + ACM import |
| **database** | DB subnet group + parameter group PostgreSQL 15 (force_ssl=1) |
| **compute** | ALB `nextcloud-dev-alb` (**actif**) + Target Group + Listener HTTPS 443 + Listener HTTP→HTTPS redirect + Launch Template (IMDSv2, EBS KMS) + CloudWatch Log Group |

**ALB DNS** : `nextcloud-dev-alb-1875997584.eu-west-3.elb.amazonaws.com`
→ Répond 503 (Target Group vide, pas d'instances derrière)

### Ressources bloquées ❌ — restrictions compte formation

Ces erreurs se produisent au **`terraform apply`** (pas au plan — le plan passe toujours sans erreur).

#### IAM — `iam:CreateRole`
```
AccessDenied: User: arn:aws:iam::039497794217:user/etudiant32 is not authorized
to perform: iam:CreateRole on resource: arn:aws:iam::039497794217:role/nextcloud-dev-ec2-role
with an explicit deny in an identity-based policy:
arn:aws:iam::039497794217:policy/formation-deny-iam-write
```
→ Policy groupe `formation-deny-iam-write` — deny explicite sur toutes les opérations IAM write

#### RDS — `rds:CreateDBInstance`
```
AccessDenied: User: arn:aws:iam::039497794217:user/etudiant32 is not authorized
to perform: rds:CreateDBInstance on resource: arn:aws:rds:eu-west-3:039497794217:db:nextcloud-dev-db
with an explicit deny in a permissions boundary:
arn:aws:iam::039497794217:policy/formation-permissions-boundary-paris
```
→ Permissions boundary Paris — RDS considéré trop coûteux pour la formation

#### ASG — `autoscaling:CreateAutoScalingGroup`
```
AccessDenied: You are not authorized to use launch template: lt-036faa78d6898e9e5
```
→ `ec2:RunInstances` sur la ressource `launch-template` non autorisé (pas de policy allow explicite)

### Adaptations faites pour contourner les restrictions

| Problème rencontré | Solution appliquée |
|--------------------|--------------------|
| `iam:CreateRole` bloqué | Variable `create_iam_resources = false` → module IAM désactivé via `count = 0` |
| Enhanced Monitoring RDS nécessite un rôle IAM | `monitoring_interval = 0` (désactivé) |
| VPC Flow Logs nécessite un rôle IAM | Variable `enable_flow_logs = false` → `count = 0` |
| Instance profile absent → Launch Template optionnel | `dynamic "iam_instance_profile"` avec `for_each` conditionnel |
| AMI ID incorrecte (`ami-0e9085a8d461c2d01` inexistante) | Corrigé en `ami-0c7191dc6b3e08b56` (AL2023, avril 2026) |
| `formation-require-owner-tag` bloque `ec2:RunInstances` | Tag `Owner = etudiant32` ajouté aux `tag_specifications` (instance + volume + network-interface) |
| Dépendance circulaire `db_host` → compute dépend de database | Variable `db_host_override` + `default = "db-not-deployed.internal"` |
| `object_lock` bucket S3 + `filter {}` lifecycle manquant | Ajoutés (warnings provider AWS 5.x) |
| NAT Gateway absent → EC2 privés ne peuvent pas pull Docker | `aws_nat_gateway` + EIP ajoutés dans le module networking |

---

## Structure des fichiers

```
~/nextcloud-aws/
├── .gitignore                          # Exclut .terraform/, *.tfstate, *.tfvars, *.pem
├── .tflint.hcl                         # Config tflint avec ruleset AWS
├── README.md                           # Guide de déploiement
├── WHAT_WAS_DONE.md                    # Ce fichier
│
├── bootstrap/                          # Phase 1 — à exécuter une seule fois
│   ├── providers.tf                    # AWS ~>5.0 + random, required_version >= 1.10
│   ├── main.tf                         # KMS key + S3 bucket state (object_lock)
│   ├── variables.tf                    # aws_region, project_name, environment
│   └── outputs.tf                      # state_bucket_name, kms_key_arn
│
├── modules/
│   ├── kms/
│   │   ├── main.tf                     # aws_kms_key (rotation=true) + aws_kms_alias
│   │   ├── variables.tf
│   │   └── outputs.tf                  # key_arn, key_id, alias_arn
│   │
│   ├── networking/
│   │   ├── main.tf                     # VPC, subnets, IGW, NAT GW, route tables,
│   │   │                               # SGs (sans 0.0.0.0/0 egress),
│   │   │                               # VPC Endpoints S3+SecretsManager,
│   │   │                               # VPC Flow Logs optionnels (enable_flow_logs)
│   │   ├── variables.tf
│   │   └── outputs.tf                  # vpc_id, subnet_ids, sg_*_id, nat_gateway_ip
│   │
│   ├── storage/
│   │   ├── main.tf                     # S3 nextcloud-data (KMS, versioning, TLS)
│   │   │                               # S3 alb-logs (AES256, lifecycle 90j, filter{})
│   │   │                               # Logging nextcloud-data → alb-logs
│   │   ├── variables.tf
│   │   └── outputs.tf                  # bucket_name, bucket_arn (× 2)
│   │
│   ├── secrets/
│   │   ├── main.tf                     # random_password × 2 → Secrets Manager
│   │   │                               # Payload JSON {username, password}
│   │   ├── variables.tf
│   │   └── outputs.tf                  # db_secret_arn, admin_secret_arn, db_password
│   │
│   ├── database/
│   │   ├── main.tf                     # RDS PostgreSQL 15, Multi-AZ, KMS
│   │   │                               # Parameter group force_ssl=1
│   │   │                               # Performance Insights (Enhanced Monitoring désactivé)
│   │   │                               # #tfsec:ignore deletion_protection (TP)
│   │   ├── variables.tf
│   │   └── outputs.tf                  # db_endpoint, db_address, db_port
│   │
│   ├── iam/
│   │   ├── main.tf                     # IAM Role EC2 + Instance Profile (count conditionnel)
│   │   │                               # Policies minimales : S3, Secrets, KMS, Logs
│   │   │                               # create_iam_resources = false → tout skippé
│   │   ├── variables.tf
│   │   └── outputs.tf                  # instance_profile_name (null si désactivé)
│   │
│   ├── certificates/
│   │   ├── main.tf                     # tls_private_key RSA 2048
│   │   │                               # tls_self_signed_cert (8760h)
│   │   │                               # aws_acm_certificate (import self-signed)
│   │   ├── variables.tf
│   │   └── outputs.tf                  # acm_certificate_arn
│   │
│   └── compute/
│       ├── main.tf                     # ALB HTTPS (drop_invalid_headers, access_logs)
│       │                               # Redirect HTTP→HTTPS
│       │                               # Launch Template IMDSv2 (http_tokens=required)
│       │                               # EBS root chiffré KMS
│       │                               # Tag Owner sur instance+volume+network-interface
│       │                               # ASG min=1 max=2 (non déployé — compte formation)
│       │                               # CloudWatch Log Group /nextcloud/docker
│       ├── variables.tf
│       ├── outputs.tf                  # alb_dns_name, asg_name, cloudwatch_log_group
│       └── templates/
│           └── user_data.sh.tpl        # IMDSv2 token, dnf update, Docker,
│                                       # aws-cli, Secrets Manager → passwords,
│                                       # docker run nextcloud:28-apache -p 8080:80
│                                       # awslogs driver → CloudWatch
│
├── envs/dev/
│   ├── backend.tf                      # S3 backend, use_lockfile=true (Terraform 1.10)
│   ├── providers.tf                    # AWS + TLS + random, required_version >= 1.10
│   ├── main.tf                         # Orchestration des 8 modules avec dépendances
│   ├── variables.tf                    # Toutes les variables avec valeurs par défaut
│   ├── outputs.tf                      # alb_url, db_endpoint, bucket, secrets ARNs
│   ├── terraform.tfvars.example        # Template à copier en terraform.tfvars
│   └── backend.tfvars.example          # Template à copier en backend.tfvars
│
└── .github/workflows/
    └── terraform-plan.yml              # CI/CD : tfsec → validate → plan → PR comment
                                        # OIDC AWS (pas de clés statiques)
```

---

## Choix techniques importants

### Sécurité

| Sujet | Solution retenue |
|-------|-----------------|
| Chiffrement au repos | Une seule clé KMS CMK partagée (S3, RDS, EBS, Secrets, Flow Logs) |
| Rotation des clés | `enable_key_rotation = true` |
| Métadonnées EC2 | IMDSv2 obligatoire (`http_tokens = "required"`) |
| Credentials EC2 | IAM Instance Profile uniquement — zéro clé statique |
| Secrets | Secrets Manager avec KMS, payloads JSON |
| TLS ALB | Certificat self-signed importé dans ACM (à remplacer par un vrai cert en prod) |
| Clé privée TLS | Stockée dans le state — le state est chiffré KMS (garanti par backend.tf) |
| Egress SGs | Pas de `0.0.0.0/0` — flux explicitement bornés vers RDS, VPC endpoints |
| ALB | `drop_invalid_header_fields = true` |
| S3 | Public access block + force-TLS policy sur tous les buckets |
| State Terraform | `use_lockfile = true` (natif 1.10) + `object_lock_enabled = true` |

### Réseau (10.0.0.0/16, eu-west-3a/3b)

```
Internet
   │ HTTPS 443
[ALB] ←── sg_alb (ingress 443/80, egress 8080→sg_ec2)      ← déployé ✅
   │ HTTP 8080
[EC2 ASG] ←── sg_ec2 (ingress 8080←sg_alb, egress 5432→sg_rds + 443→VPC)  ← non déployé ❌
   │ PostgreSQL 5432
[RDS Multi-AZ] ←── sg_rds (ingress 5432←sg_ec2)            ← non déployé ❌

VPC Endpoints : S3 Gateway (gratuit) + Secrets Manager Interface  ← déployés ✅
NAT Gateway : subnet public[0] → accès internet pour EC2 privés   ← déployé ✅
```

### tfsec — explications des ignores

| Règle ignorée | Raison |
|---------------|--------|
| `aws-s3-encryption-customer-key` (alb-logs) | AWS ELB ne supporte pas SSE-KMS sur les buckets de logs ALB |
| `aws-elb-alb-not-public` | ALB public intentionnel — c'est le point d'entrée des utilisateurs |
| `aws-rds-enable-deletion-protection` | Désactivé pour faciliter les destroy en TP/dev |
| `aws-iam-no-policy-wildcards` (networking/iam) | Wildcards région/compte inévitables dans un module réutilisable |

---

## Séquence de déploiement

### Prérequis
- Terraform >= 1.10
- AWS CLI configuré (`AWS_PROFILE=formation`)
- Droits IAM suffisants (IAM, S3, KMS, RDS, EC2, ALB, Secrets Manager, ACM)

### Phase 1 — Bootstrap (déjà fait ✅)

```bash
cd ~/nextcloud-aws/bootstrap/
terraform init
terraform apply
```

Créé :
- KMS `alias/nextcloud-terraform-state` → `arn:aws:kms:eu-west-3:039497794217:key/ffc0e81b-...`
- S3 state bucket → `nextcloud-terraform-state-039497794217-eb168a63`

### Phase 2 — Environnement dev (partiellement déployé)

```bash
cd ~/nextcloud-aws/envs/dev/
# backend.tfvars déjà rempli avec les outputs bootstrap
terraform init -backend-config=backend.tfvars
terraform plan -var-file=terraform.tfvars.example   # → toujours OK, 0 erreur
terraform apply -var-file=terraform.tfvars.example  # → 64 ressources OK, 3 bloquées
```

### Sur un compte AWS sans restrictions

Remplacer dans `envs/dev/main.tf` :
```hcl
create_iam_resources = true   # dans module.iam
enable_flow_logs     = true   # dans module.networking
```
Et retirer le `db_host_override`. Tout se déploie en une seule passe.

---

## CI/CD — GitHub Actions (Bonus T16)

Fichier : `.github/workflows/terraform-plan.yml`

**Déclenchement** : Pull Request sur `main` touchant `envs/dev/**` ou `modules/**`

**Pipeline** :
1. `tfsec` — scan sécurité (fail sur HIGH/CRITICAL)
2. Configure AWS via **OIDC** (pas de clés statiques dans les secrets)
3. `terraform init` avec backend dynamique
4. `terraform validate`
5. `terraform plan`
6. Commentaire automatique sur la PR avec le résultat

**Secrets GitHub à configurer** :
- `AWS_ROLE_ARN` — ARN du rôle IAM avec trust OIDC GitHub Actions
- `TF_STATE_BUCKET` → `nextcloud-terraform-state-039497794217-eb168a63`
- `TF_STATE_KMS_KEY_ARN` → `arn:aws:kms:eu-west-3:039497794217:key/ffc0e81b-56dd-435f-81e8-3eb566788bd3`

---

## Ce qu'il reste à faire pour une vraie prod

- Obtenir des droits IAM complets (supprimer `formation-deny-iam-write` et `formation-permissions-boundary-paris`)
- Remplacer le certificat self-signed par un certificat ACM validé DNS (Route53)
- Activer `deletion_protection = true` sur RDS
- Mettre `asg_min_size = 2` pour la haute disponibilité réelle
- Configurer un domaine Route53 pointant sur l'ALB
- Activer AWS Backup pour RDS
- Revoir les AMI IDs régulièrement (`ami-0c7191dc6b3e08b56` = AL2023 kernel 6.1, avril 2026)
