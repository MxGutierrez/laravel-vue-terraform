resource "aws_ecr_repository" "backend" {
  name = "backend"
}

resource "aws_ecr_repository" "nginx" {
  name = "nginx"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "backend"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  # Fargate has specific cpu and memory combinations
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
  cpu    = 256
  memory = 512

  container_definitions = templatefile("${abspath(path.root)}/../backend/taskdef.json", {
    BACKEND_IMAGE_PATH = aws_ecr_repository.backend.repository_url
    NGINX_IMAGE_PATH   = aws_ecr_repository.nginx.repository_url
  })
}

resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.discovery.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 15
      type = "A"
    }
  }
}

resource "aws_security_group" "backend_task" {
  name   = "backend-task-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-task-sg"
  }
}

resource "aws_ecs_service" "backend" {
  name                               = "backend"
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.backend.arn
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1

  network_configuration {
    subnets         = aws_subnet.apps[*].id
    security_groups = [aws_security_group.backend_task.id]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.backend.arn
    container_name   = "nginx"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend.arn
  }

  depends_on = [aws_lb.alb]
}

resource "aws_alb_target_group" "backend" {
  name        = "backend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    matcher             = 200
    timeout             = 3
    path                = "/api/test"
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_codebuild_project" "backend" {
  name         = "backend"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "./backend/buildspec.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:3.0"
    type         = "LINUX_CONTAINER"

    // Use privileged mode otherwise build errors out when building image:
    // Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
    // See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#privileged_mode
    privileged_mode = true

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.id
    }

    // Use secrets manager on real builds:
    // https://stackoverflow.com/questions/64967922/docker-hub-login-for-aws-codebuild-docker-hub-limit
    environment_variable {
      name  = "DOCKERHUB_USERNAME"
      value = var.dockerhub_username
    }

    environment_variable {
      name  = "DOCKERHUB_PASSWORD"
      value = var.dockerhub_password
    }

    environment_variable {
      name  = "BACKEND_REPOSITORY_URL"
      value = aws_ecr_repository.backend.repository_url
    }

    environment_variable {
      name  = "NGINX_REPOSITORY_URL"
      value = aws_ecr_repository.nginx.repository_url
    }
  }
}
