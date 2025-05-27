# modules/ecs/outputs.tf
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "auth_service_id" {
  description = "ID of the auth service"
  value       = aws_ecs_service.auth_service.id
}

output "user_service_id" {
  description = "ID of the user service"
  value       = aws_ecs_service.user_service.id
}

output "task_service_id" {
  description = "ID of the task service"
  value       = aws_ecs_service.task_service.id
}

output "auth_target_group_arn" {
  description = "ARN of the auth service target group"
  value       = aws_lb_target_group.auth_service.arn
}

output "user_target_group_arn" {
  description = "ARN of the user service target group"
  value       = aws_lb_target_group.user_service.arn
}

output "task_target_group_arn" {
  description = "ARN of the task service target group"
  value       = aws_lb_target_group.task_service.arn
}