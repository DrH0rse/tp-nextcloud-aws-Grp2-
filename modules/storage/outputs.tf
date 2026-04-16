output "nextcloud_bucket_name" {
  description = "Nom du bucket Nextcloud data"
  value       = aws_s3_bucket.nextcloud_data.bucket
}

output "nextcloud_bucket_arn" {
  description = "ARN du bucket Nextcloud data"
  value       = aws_s3_bucket.nextcloud_data.arn
}

output "alb_logs_bucket_name" {
  description = "Nom du bucket ALB logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "alb_logs_bucket_arn" {
  description = "ARN du bucket ALB logs"
  value       = aws_s3_bucket.alb_logs.arn
}
