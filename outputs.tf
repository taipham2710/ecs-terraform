# Root outputs.tf
output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.ecs.load_balancer_dns
}

output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = module.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins server URL"
  value       = "http://${module.jenkins.public_ip}:8080"
}

output "auth_service_id" {
  description = "ID of the auth service"
  value       = module.ecs.auth_service_id
}

output "user_service_id" {
  description = "ID of the user service"
  value       = module.ecs.user_service_id
}

output "task_service_id" {
  description = "ID of the task service"
  value       = module.ecs.task_service_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}