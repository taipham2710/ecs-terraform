variable "lb_name" {
  type        = string
  description = "Tên load balancer"
}
variable "security_group_ids" {
  type        = list(string)
  description = "Security group cho LB"
}
variable "subnet_ids" {
  type        = list(string)
  description = "Subnet cho LB"
}
variable "default_target_group_arn" {
  type        = string
  description = "Target group mặc định"
}