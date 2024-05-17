# Define variables
variable "aws_region" {
  description = "AWS region where resources will be created"
  default     = "us-east-1"  # Change to your desired region
}

# Define ECS task definition JSON
variable "ecs_task_definition" {
  default = <<TASK_DEFINITION
{
  "family": "my-task",
  "containerDefinitions": [
    {
      "name": "my-container",
      "image": "your-docker-image",
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 0
        }
      ]
    }
  ],
  "cpu": "256",
  "memory": "512"
}
TASK_DEFINITION
}

# Define ECS service definition JSON
variable "ecs_service_definition" {
  default = <<SERVICE_DEFINITION
{
  "serviceName": "my-service",
  "taskDefinition": "my-task",
  "desiredCount": 1,
  "launchType": "FARGATE",
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": ["subnet-12345678"],
      "assignPublicIp": "ENABLED"
    }
  }
}
SERVICE_DEFINITION
}

# Create IAM policy
resource "aws_iam_policy" "ecs_policy" {
  name        = "ecs-policy"
  description = "Policy for ECS/Fargate service"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create IAM role and attach policy
resource "aws_iam_role" "ecs_role" {
  name               = "ecs-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_attachment" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = aws_iam_policy.ecs_policy.arn
}

# Create ECS cluster, task definition, and service
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task"
  container_definitions    = var.ecs_task_definition
}

resource "aws_ecs_service" "my_service" {
  name                    = "my-service"
  cluster                 = aws_ecs_cluster.my_cluster.id
  task_definition         = aws_ecs_task_definition.my_task.arn
  desired_count           = 1
  launch_type             = "FARGATE"
  network_configuration   = jsondecode(var.ecs_service_definition)["networkConfiguration"]
}
