# modules/networking/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs.id
}

output "jenkins_security_group_id" {
  description = "ID of the Jenkins security group"
  value       = aws_security_group.jenkins.id
}