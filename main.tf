# --- Networking prerequisites ---

resource "aws_vpc" "muzique_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "muzique_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.muzique_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.muzique_vpc.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

data "aws_availability_zones" "available" {}


resource "aws_security_group" "muzique_sg" {
  name        = "muzique-sg"
  description = "Allow HTTP and ECS"
  vpc_id      = aws_vpc.muzique_vpc.id

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

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and HTTP for Jenkins"
  vpc_id      = aws_vpc.muzique_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_internet_gateway" "muzique_igw" {
  vpc_id = aws_vpc.muzique_vpc.id
}

resource "aws_route_table" "muzique_public_rt" {
  vpc_id = aws_vpc.muzique_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.muzique_igw.id
  }
}

resource "aws_route_table_association" "muzique_public_assoc" {
  count          = length(aws_subnet.muzique_subnets)
  subnet_id      = aws_subnet.muzique_subnets[count.index].id
  route_table_id = aws_route_table.muzique_public_rt.id
}


resource "aws_instance" "jenkins" {
  ami                    = "ami-05205ed95a034f9bb"
  instance_type          = "t3.micro"
  key_name               = "muzique-jenkins"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.muzique_subnets[0].id
  associate_public_ip_address = true
  availability_zone      = data.aws_availability_zones.available.names[0]
  user_data = <<-EOF
              #!/bin/bash

              # Ref - https://bluevps.com/blog/how-to-install-java-on-ubuntu
              # Installing Java 
              sudo apt update -y 
              sudo apt install openjdk-21-jre -y
              sudo apt install openjdk-21-jdk -y
              java --version


              # Ref - https://www.jenkins.io/doc/book/installing/linux/
              # Installing Jenkins
              sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
                https://pkg.jenkins.io/debian/jenkins.io-2023.key
              echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
                https://pkg.jenkins.io/debian binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update -y
              sudo apt-get install jenkins -y

              # Enable Jenkins service

              sudo systemctl enable jenkins
              sudo systemctl start jenkins

              # Ref - https://github.com/jenkinsci/plugin-installation-manager-tool - tools: https://plugins.jenkins.io/
              # Installing jenkins CLI and plugin

              sudo wget https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.13.2/jenkins-plugin-manager-2.13.2.jar -O jenkins-plugin-manager.jar
              java -jar jenkins-plugin-manager.jar --plugin-download-directory ./plugins \
                --plugins adoptopenjdk sonar nodejs docker-plugin docker-commons docker-workflow \
                docker-java-api docker-build-step dependency-check-jenkins-plugin terraform aws-credentials \
                pipeline-aws snyk-security-scanner golang github-pullrequest github-api github

              sudo cp ./plugins/*.jpi /var/lib/jenkins/plugins/
              sudo chown jenkins:jenkins /var/lib/jenkins/plugins/*.jpi
              sudo systemctl restart jenkins

              # Ref - https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
              # Installing docker 
              sudo apt update -y
              sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt update -y
              sudo apt install docker-ce -y

              # Cấp quyền sử dụng docker
              sudo usermod -aG docker jenkins
              sudo usermod -aG docker ubuntu
              sudo systemctl restart docker 
              sudo chmod 777 /var/run/docker.sock
              sudo docker --version

              # Ref - 
              # run Docker container of sonarqube
              sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community

              # Installing AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              sudo apt install unzip -y
              unzip awscliv2.zip
              sudo ./aws/install

              # Ref - https://v1-31.docs.kubernetes.io/vi/docs/tasks/tools/install-kubectl/
              # Installing kubectl 
              sudo apt update -y
              sudo apt install curl -y
              sudo curl -LO https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl
              sudo chmod +x kubectl
              sudo mv kubectl /usr/local/bin/
              kubectl version --client

              # Ref - https://developer.hashicorp.com/terraform/install?product_intent=terraform
              # Installing Terraform
              wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
              sudo apt update -y 
              sudo apt install terraform -y


              # Ref - https://trivy.dev/latest/getting-started/installation/#__tabbed_2_1
              # Installing Trivy
              sudo apt-get install wget gnupg
              wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
              echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
              sudo apt-get update
              sudo apt-get install trivy


              # Ref - 
              # Installing Helm
              curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
              sudo apt-get install apt-transport-https --yes
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
              sudo apt-get update -y
              sudo apt-get install helm -y

              # Ref - https://nodejs.org/en/download
              # Installing nvm && node
              apt update -y
              apt install -y curl
              curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
              apt install -y nodejs

              # Ref - https://www.npmjs.com/package/snyk?activeTab=readme
              # Installing snyk
              npm install -g snyk
              snyk --version


              # Ref - 
              # Installing jq
              sudo apt install jq -y
              EOF
  tags = {
    Name = "jenkins-server"
  }
}


resource "aws_ecs_cluster" "muzique_cluster" {
  name = "muzique-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

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
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

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
}

resource "aws_ecs_task_definition" "auth_service" {
  family                   = "auth-service-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = "auth-service"
      image     = "minhphuc2544/muzique-auth-service"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])

}

resource "aws_ecs_task_definition" "user_service" {
  family                   = "user-service-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = "user-service"
      image     = "minhphuc2544/muzique-user-service"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "task_service" {
  family                   = "task-service-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = "task-service"
      image     = "minhphuc2544/muzique-task-service"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_lb" "muzique_lb" {
  name               = "muzique-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.muzique_sg.id]
  subnets            = aws_subnet.muzique_subnets[*].id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.muzique_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_service.arn
  }
}

resource "aws_lb_target_group" "auth_service" {
  name        = "auth-service"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.muzique_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 300
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = "200-499"
  }
}

resource "aws_lb_target_group" "user_service" {
  name        = "user-service"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.muzique_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 300
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = "200-499"
  }
}

resource "aws_lb_target_group" "task_service" {
  name        = "task-service"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.muzique_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 300
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = "200-499"
  }
}

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

resource "aws_ecs_service" "auth_service" {
  name            = "auth-service"
  cluster         = aws_ecs_cluster.muzique_cluster.id
  task_definition = aws_ecs_task_definition.auth_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.muzique_subnets[*].id
    security_groups  = [aws_security_group.muzique_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.auth_service.arn
    container_name   = "auth-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.auth_rule]
}

resource "aws_ecs_service" "user_service" {
  name            = "user-service"
  cluster         = aws_ecs_cluster.muzique_cluster.id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.muzique_subnets[*].id
    security_groups  = [aws_security_group.muzique_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.user_service.arn
    container_name   = "user-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.user_rule]
}

resource "aws_ecs_service" "task_service" {
  name            = "task-service"
  cluster         = aws_ecs_cluster.muzique_cluster.id
  task_definition = aws_ecs_task_definition.task_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.muzique_subnets[*].id
    security_groups  = [aws_security_group.muzique_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.task_service.arn
    container_name   = "task-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener_rule.task_rule]
}


