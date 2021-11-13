resource "aws_ecs_task_definition" "task_definition" {
  family             = var.task_name
  execution_role_arn = var.execution_role_arn

  container_definitions = templatefile(var.container_definitions_path, {
    IMAGE_PATH = var.ecr_repository_url
  })
}
