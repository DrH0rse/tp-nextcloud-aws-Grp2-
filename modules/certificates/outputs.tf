output "acm_certificate_arn" {
  description = "ARN du certificat ACM importé"
  value       = aws_acm_certificate.nextcloud.arn
}

output "certificate_pem" {
  description = "Certificat TLS (PEM)"
  value       = tls_self_signed_cert.nextcloud.cert_pem
  sensitive   = false
}
