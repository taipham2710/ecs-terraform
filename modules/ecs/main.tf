# modules/ecs/main.tf

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# IAM Roles
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  tags = {
    Name = "${var.project_name}-load-balancer"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_service.arn
  }
}

# Target Groups
resource "aws_lb_target_group" "auth_service" {
  name        = "${var.project_name}-auth-service"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 300
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = "200-499"
  }

  tags = {
    Name = "${var.project_name}-auth-service-tg"
  }
}

resource "aws_lb_target_group" "user_service" {
  name        = "${var.project_name}-user-service"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 300
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = "200-499"
  }

  tags = {
    Name = "${var.project_name}-user-service-tg"
  }
}

resource "aws_lb_target_group" "task_service" {
  name        = "${var.project_name}-task-service"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 300
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = "200-499"
  }

  tags = {
    Name = "${var.project_name}-task-service-tg"
  }
}

# Load Balancer Rules
resource "aws_lb_listener_rule" "auth_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_service.arn
  }

  condition {
    path_pattern {
      values = ["/auth/*"]
    }
  }
}

resource "aws_lb_listener_rule" "user_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_service.arn
  }

  condition {
    path_pattern {
      values = ["/user/*"]
    }
  }
}

resource "aws_lb_listener_rule" "task_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.task_service.arn
  }

  condition {
    path_pattern {
      values = ["/task/*"]
    }
  }
}

# Task Definitions
resource "aws_ecs_task_definition" "auth_service" {
  family                   = "${var.project_name}-auth-service-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "auth-service"
      image     = var.auth_service_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-auth-service"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-auth-service-task"
  }
}

resource "aws_ecs_task_definition" "user_service" {
  family                   = "${var.project_name}-user-service-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "user-service"
      image     = var.user_service_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-user-service"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-user-service-task"
  }
}

resource "aws_ecs_task_definition" "task_service" {
  family                   = "${var.project_name}-task-service-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "task-service"
      image     = var.task_service_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-task-service"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-task-service-task"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "auth_service" {
  name              = "/ecs/${var.project_name}-auth-service"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-auth-service-logs"
  }
}

resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/ecs/${var.project_name}-user-service"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-user-service-logs"
  }
}

resource "aws_cloudwatch_log_group" "task_service" {
  name              = "/ecs/${var.project_name}-task-service"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-task-service-logs"
  }
}

# ECS Services
resource "aws_ecs_service" "auth_service" {
  name            = "${var.project_name}-auth-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.auth_service.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.auth_service.arn
    container_name   = "auth-service"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener_rule.auth_rule]

  tags = {
    Name = "${var.project_name}-auth-service"
  }
}

resource "aws_ecs_service" "user_service" {
  name            = "${var.project_name}-user-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.user_service.arn
    container_name   = "user-service"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener_rule.user_rule]

  tags = {
    Name = "${var.project_name}-user-service"
  }
}

resource "aws_ecs_service" "task_service" {
  name            = "${var.project_name}-task-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.task_service.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.task_service.arn
    container_name   = "task-service"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener_rule.task_rule]

  tags = {
    Name = "${var.project_name}-task-service"
  }
}

# Data source for current AWS region
data "aws_region" "current" {}