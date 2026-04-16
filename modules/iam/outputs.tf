output "instance_profile_name" {
  description = "Nom de l'Instance Profile EC2 (null si create_iam_resources = false)"
  value       = var.create_iam_resources ? aws_iam_instance_profile.nextcloud[0].name : null
}

output "instance_profile_arn" {
  description = "ARN de l'Instance Profile EC2 (null si create_iam_resources = false)"
  value       = var.create_iam_resources ? aws_iam_instance_profile.nextcloud[0].arn : null
}

output "role_arn" {
  description = "ARN du Role IAM EC2 (null si create_iam_resources = false)"
  value       = var.create_iam_resources ? aws_iam_role.nextcloud_ec2[0].arn : null
}
