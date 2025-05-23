# ECS Terraform Project

This project sets up an Amazon ECS (Elastic Container Service) environment using Terraform. It deploys three microservices, each running in its own container, and configures a load balancer to route traffic to these services based on specific paths.

## Services

The following services are deployed:

- **Auth Service**: Pulls the Docker image from `minhphuc2544/muzique-auth-service`
- **User Service**: Pulls the Docker image from `minhphuc2544/muzique-user-service`
- **Task Service**: Pulls the Docker image from `minhphuc2544/muzique-task-service`

## Load Balancer

The load balancer is configured to route traffic to the appropriate service based on the following paths:

- `/auth` -> Auth Service
- `/user` -> User Service
- `/task` -> Task Service

All services expose port 8080.

## Prerequisites

- Terraform installed on your local machine.
- AWS account with appropriate permissions to create ECS resources.
- AWS CLI configured with your credentials.

## Getting Started

1. Clone the repository:
   ```
   git clone <repository-url>
   cd ecs-terraform-project
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Review the configuration:
   ```
   terraform plan
   ```

4. Apply the configuration:
   ```
   terraform apply
   ```

5. Access the services via the load balancer's DNS name, using the specified paths.

## Outputs

After applying the configuration, the following outputs will be available:

- DNS name of the load balancer
- ARNs of the created ECS services

## Cleanup

To remove all resources created by this project, run:
```
terraform destroy
```