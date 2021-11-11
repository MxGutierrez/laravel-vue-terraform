resource "aws_ecs_cluster" "cluster" {
  name = "ecs-cluster"
}

resource "aws_iam_role" "task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_execution_policy_attachment" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "frontend" {
  family             = "frontend"
  execution_role_arn = aws_iam_role.task_execution_role.arn

  container_definitions = templatefile("../frontend/taskdef.json", {
    IMAGE_PATH = "${aws_ecr_repository.ecrs["frontend"].repository_url}:latest"
  })
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.frontend.arn
  deployment_minimum_healthy_percent = 0
  desired_count   = 1

  lifecycle {
    ignore_changes = [task_definition]
  }
}
