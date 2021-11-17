resource "aws_ecr_repository" "backend" {
  name = "backend"
}

resource "aws_ecr_repository" "nginx" {
  name = "nginx"
}

resource "aws_ecs_task_definition" "backend" {
  family             = "backend"
  execution_role_arn = aws_iam_role.task_execution_role.arn

  container_definitions = templatefile("${abspath(path.root)}/../backend/taskdef.json", {
    BACKEND_IMAGE_PATH = aws_ecr_repository.backend.repository_url
    NGINX_IMAGE_PATH   = aws_ecr_repository.nginx.repository_url
  })
}

resource "aws_ecs_service" "backend" {
  name                               = "backend"
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.backend.arn
  deployment_minimum_healthy_percent = 1
  desired_count                      = 2

  load_balancer {
    target_group_arn = aws_alb_target_group.backend.arn
    container_name   = "nginx"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [aws_lb.alb]
}

resource "aws_alb_target_group" "backend" {
  name        = "backend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "instance"

  health_check {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    matcher             = 200
    timeout             = 3
    path                = "/"
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.http.arn

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
