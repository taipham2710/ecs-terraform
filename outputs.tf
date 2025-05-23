output "load_balancer_dns" {
  value = aws_lb.muzique_lb.dns_name
}

output "auth_service_id" {
  value = aws_ecs_service.auth_service.id
}

output "user_service_id" {
  value = aws_ecs_service.user_service.id
}

output "task_service_id" {
  value = aws_ecs_service.task_service.id
}