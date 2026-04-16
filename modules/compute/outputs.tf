output "alb_dns_name" {
  description = "DNS name de l'Application Load Balancer"
  value       = aws_lb.nextcloud.dns_name
}

output "alb_arn" {
  description = "ARN de l'Application Load Balancer"
  value       = aws_lb.nextcloud.arn
}

output "alb_zone_id" {
  description = "Zone ID de l'ALB (pour Route53)"
  value       = aws_lb.nextcloud.zone_id
}

output "asg_name" {
  description = "Nom de l'Auto Scaling Group"
  value       = var.create_asg ? aws_autoscaling_group.nextcloud[0].name : null
}

output "launch_template_id" {
  description = "ID du Launch Template"
  value       = aws_launch_template.nextcloud.id
}

output "cloudwatch_log_group" {
  description = "Nom du log group CloudWatch pour les containers Docker"
  value       = aws_cloudwatch_log_group.nextcloud_docker.name
}
