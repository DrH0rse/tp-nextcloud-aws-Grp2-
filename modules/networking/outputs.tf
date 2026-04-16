output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs des subnets publics"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs des subnets privés"
  value       = aws_subnet.private[*].id
}

output "sg_alb_id" {
  description = "ID du Security Group ALB"
  value       = aws_security_group.alb.id
}

output "sg_ec2_id" {
  description = "ID du Security Group EC2"
  value       = aws_security_group.ec2.id
}

output "sg_rds_id" {
  description = "ID du Security Group RDS"
  value       = aws_security_group.rds.id
}

output "nat_gateway_ip" {
  description = "IP publique du NAT Gateway"
  value       = aws_eip.nat.public_ip
}
