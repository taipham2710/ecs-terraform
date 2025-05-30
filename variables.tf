# Root variables.tf
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "muzique"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Jenkins variables
variable "jenkins_key_name" {
  description = "EC2 Key Pair name for Jenkins instance"
  type        = string
  default     = "muzique-jenkins"
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.micro"
}

# ECS Service variables
variable "auth_service_image" {
  description = "Docker image for auth service"
  type        = string
  default     = "minhphuc2544/muzique-auth-service"
}

variable "user_service_image" {
  description = "Docker image for user service"
  type        = string
  default     = "minhphuc2544/muzique-user-service"
}

variable "task_service_image" {
  description = "Docker image for task service"
  type        = string
  default     = "minhphuc2544/muzique-task-service"
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