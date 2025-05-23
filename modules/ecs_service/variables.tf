variable "service_name" { type = string }
variable "image" { type = string }
variable "container_port" { type = number }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "cluster_id" { type = string }
variable "execution_role_arn" { type = string }
variable "task_role_arn" { type = string }
variable "desired_count" { 
  type = number
  default = 1 
}
variable "cpu" { 
  type = string 
  default = "256" 
}
variable "memory" { 
  type = string 
  default = "512" 
}
variable "listener_arn" { type = string }
variable "priority" { type = number }
variable "path_pattern" { type = string }