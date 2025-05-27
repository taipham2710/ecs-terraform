# Root main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  project_name         = var.project_name
}

# Jenkins Module
module "jenkins" {
  source = "./modules/jenkins"
  
  vpc_id              = module.networking.vpc_id
  subnet_id           = module.networking.public_subnet_ids[0]
  security_group_id   = module.networking.jenkins_security_group_id
  availability_zone   = data.aws_availability_zones.available.names[0]
  key_name            = var.jenkins_key_name
  instance_type       = var.jenkins_instance_type
  project_name        = var.project_name
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"
  
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.public_subnet_ids
  security_group_id     = module.networking.ecs_security_group_id
  project_name          = var.project_name
  
  # Service configurations
  auth_service_image    = var.auth_service_image
  user_service_image    = var.user_service_image
  task_service_image    = var.task_service_image
  container_port        = var.container_port
  
  # Task resource configurations
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  desired_count         = var.desired_count
}