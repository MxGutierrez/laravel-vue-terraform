resource "aws_ecs_service" "service" {
  name                               = var.name
  cluster                            = var.cluster_id
  task_definition                    = var.task_definition_arn
  deployment_minimum_healthy_percent = 100
  desired_count                      = var.desired_count

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
