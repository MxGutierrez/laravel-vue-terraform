resource "aws_ecs_service" "service" {
  name                               = var.name
  cluster                            = var.cluster_id
  task_definition                    = var.task_definition_arn
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1

  lifecycle {
    ignore_changes = [task_definition]
  }
}
