output "load_balancer_dns" {
  value = module.load_balancer.lb_dns_name
}
output "auth_service_id" {
  value = module.auth_service.service_id
}
output "user_service_id" {
  value = module.user_service.service_id
}
output "task_service_id" {
  value = module.task_service.service_id
}