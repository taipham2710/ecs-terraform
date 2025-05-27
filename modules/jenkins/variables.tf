# modules/jenkins/variables.tf
variable "vpc_id" {
  description = "VPC ID where Jenkins will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Jenkins instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Jenkins"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for Jenkins instance"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for Jenkins instance"
  type        = string
  default     = "ami-05205ed95a034f9bb"  # Ubuntu 24.04 LTS
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}