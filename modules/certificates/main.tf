# ── Clé privée TLS ────────────────────────────────────────────────────────────
# ⚠️ La clé privée est stockée dans le state Terraform
# → Le state DOIT être chiffré KMS (garanti par backend.tf)
resource "tls_private_key" "nextcloud" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# ── Certificat self-signed ────────────────────────────────────────────────────
resource "tls_self_signed_cert" "nextcloud" {
  private_key_pem = tls_private_key.nextcloud.private_key_pem

  subject {
    common_name         = var.domain_name
    organization        = "Nextcloud ${var.environment}"
    organizational_unit = "Infrastructure"
  }

  validity_period_hours = var.cert_validity_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [var.domain_name]
}

# ── Import dans ACM ───────────────────────────────────────────────────────────
resource "aws_acm_certificate" "nextcloud" {
  certificate_body = tls_self_signed_cert.nextcloud.cert_pem
  private_key      = tls_private_key.nextcloud.private_key_pem

  tags = {
    Name        = "${var.project_name}-${var.environment}-cert"
    Domain      = var.domain_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}
