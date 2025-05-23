variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}
variable "subnet_count" {
  type        = number
  description = "Số lượng subnet"
  default     = 2
}