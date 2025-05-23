module "networking" {
  source       = "./modules/networking"
  vpc_cidr     = "10.0.0.0/16"
  subnet_count = 2
}

module "iam" {
  source = "./modules/iam"
}

module "ecs_cluster" {
  source           = "./modules/ecs_cluster"
  ecs_cluster_name = var.ecs_cluster_name
}

module "jenkins" {
  source        = "./modules/jenkins"
  ami           = "ami-05205ed95a034f9bb"
  instance_type = "t3.micro"
  key_name      = "muzique-jenkins"
  subnet_id     = module.networking.subnet_ids[0]
  az            = module.networking.azs[0]
  vpc_id        = module.networking.vpc_id
  user_data     = file("jenkins_userdata.sh")
}

resource "aws_security_group" "muzique_sg" {
  name        = "muzique-sg"
  description = "Allow HTTP and ECS"
  vpc_id      = module.networking.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "auth_service" {
  source             = "./modules/ecs_service"
  service_name       = var.auth_service_name
  image              = "minhphuc2544/muzique-auth-service"
  container_port     = var.container_port
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.subnet_ids
  security_group_ids = [aws_security_group.muzique_sg.id]
  cluster_id         = module.ecs_cluster.ecs_cluster_id
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  listener_arn       = module.load_balancer.listener_arn
  priority           = 100
  path_pattern       = "/auth/*"
}

module "user_service" {
  source             = "./modules/ecs_service"
  service_name       = var.user_service_name
  image              = "minhphuc2544/muzique-user-service"
  container_port     = var.container_port
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.subnet_ids
  security_group_ids = [aws_security_group.muzique_sg.id]
  cluster_id         = module.ecs_cluster.ecs_cluster_id
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  listener_arn       = module.load_balancer.listener_arn
  priority           = 200
  path_pattern       = "/user/*"
}

module "task_service" {
  source             = "./modules/ecs_service"
  service_name       = var.task_service_name
  image              = "minhphuc2544/muzique-task-service"
  container_port     = var.container_port
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.subnet_ids
  security_group_ids = [aws_security_group.muzique_sg.id]
  cluster_id         = module.ecs_cluster.ecs_cluster_id
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  listener_arn       = module.load_balancer.listener_arn
  priority           = 300
  path_pattern       = "/task/*"
}

module "load_balancer" {
  source                = "./modules/load_balancer"
  lb_name               = var.load_balancer_name
  security_group_ids    = [aws_security_group.muzique_sg.id]
  subnet_ids            = module.networking.subnet_ids
  default_target_group_arn = module.auth_service.target_group_arn
}

resource "aws_route53_zone" "main" {
  name = "muzique-backend.com"
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.muzique-backend.com"
  type    = "A"
  alias {
    name                   = module.load_balancer.lb_dns_name
    zone_id                = module.load_balancer.lb_zone_id
    evaluate_target_health = true
  }
}