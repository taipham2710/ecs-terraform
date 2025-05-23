variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "muzique-cluster"
}

variable "auth_service_name" {
  description = "The name of the authentication service"
  type        = string
  default     = "muzique-auth-service"
}

variable "user_service_name" {
  description = "The name of the user service"
  type        = string
  default     = "muzique-user-service"
}

variable "task_service_name" {
  description = "The name of the task service"
  type        = string
  default     = "muzique-task-service"
}

variable "container_port" {
  description = "The port on which the containers will listen"
  type        = number
  default     = 8080
}

variable "load_balancer_name" {
  description = "The name of the load balancer"
  type        = string
  default     = "muzique-load-balancer"
}