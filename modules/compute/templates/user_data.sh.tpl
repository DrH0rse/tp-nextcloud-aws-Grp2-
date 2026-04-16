#!/bin/bash
set -euo pipefail

# ── Variables depuis Terraform ────────────────────────────────────────────────
AWS_REGION="${aws_region}"
DB_SECRET_ARN="${db_secret_arn}"
ADMIN_SECRET_ARN="${admin_secret_arn}"
DB_HOST="${db_host}"
DB_NAME="${db_name}"
S3_BUCKET="${s3_bucket}"
LOG_GROUP="${log_group}"

# ── IMDSv2 Token ──────────────────────────────────────────────────────────────
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

# ── Mise à jour système ───────────────────────────────────────────────────────
dnf update -y

# ── Installation des dépendances ──────────────────────────────────────────────
dnf install -y docker jq

# ── AWS CLI v2 ────────────────────────────────────────────────────────────────
if ! command -v aws &>/dev/null; then
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  dnf install -y unzip
  unzip -q /tmp/awscliv2.zip -d /tmp/
  /tmp/aws/install
  rm -rf /tmp/awscliv2.zip /tmp/aws/
fi

# ── Démarrage Docker ──────────────────────────────────────────────────────────
systemctl enable --now docker

# ── Récupération des secrets ──────────────────────────────────────────────────
DB_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "$DB_SECRET_ARN" \
  --region "$AWS_REGION" \
  --query 'SecretString' \
  --output text)

ADMIN_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "$ADMIN_SECRET_ARN" \
  --region "$AWS_REGION" \
  --query 'SecretString' \
  --output text)

DB_PASSWORD=$(echo "$DB_SECRET" | jq -r '.password')
DB_USER=$(echo "$DB_SECRET" | jq -r '.username')
ADMIN_USER=$(echo "$ADMIN_SECRET" | jq -r '.username')
ADMIN_PASSWORD=$(echo "$ADMIN_SECRET" | jq -r '.password')

# ── Log group CloudWatch ──────────────────────────────────────────────────────
aws logs create-log-group \
  --log-group-name "$LOG_GROUP" \
  --region "$AWS_REGION" 2>/dev/null || true

# ── Lancement Nextcloud ───────────────────────────────────────────────────────
docker run -d \
  --name nextcloud \
  --restart unless-stopped \
  -p 8080:80 \
  -e POSTGRES_HOST="$DB_HOST" \
  -e POSTGRES_DB="$DB_NAME" \
  -e POSTGRES_USER="$DB_USER" \
  -e POSTGRES_PASSWORD="$DB_PASSWORD" \
  -e NEXTCLOUD_ADMIN_USER="$ADMIN_USER" \
  -e NEXTCLOUD_ADMIN_PASSWORD="$ADMIN_PASSWORD" \
  -e OBJECTSTORE_S3_BUCKET="$S3_BUCKET" \
  -e OBJECTSTORE_S3_REGION="$AWS_REGION" \
  -e OBJECTSTORE_S3_KEY="" \
  -e OBJECTSTORE_S3_SECRET="" \
  -e OBJECTSTORE_S3_USE_SSL="true" \
  -e OBJECTSTORE_S3_USEPATH_STYLE="false" \
  --log-driver=awslogs \
  --log-opt awslogs-region="$AWS_REGION" \
  --log-opt awslogs-group="$LOG_GROUP" \
  --log-opt awslogs-stream="$INSTANCE_ID" \
  nextcloud:28-apache

# ── Nettoyage des secrets en mémoire ─────────────────────────────────────────
unset DB_PASSWORD ADMIN_PASSWORD DB_SECRET ADMIN_SECRET
