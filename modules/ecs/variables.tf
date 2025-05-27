# modules/ecs/variables.tf
variable "vpc_id" {
  description = "VPC ID where ECS services will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS services"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS services"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "auth_service_image" {
  description = "Docker image for auth service"
  type        = string
}

variable "user_service_image" {
  description = "Docker image for user service"
  type        = string
}

variable "task_service_image" {
  description = "Docker image for task service"
  type        = string
}

variable "container_port" {
  description = "Port on which containers listen"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "CPU units for ECS tasks"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for ECS tasks"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Desired number of ECS service instances"
  type        = number
  default     = 1
}