output "id" {
  value = aws_ecs_cluster.cluster.id
}

output "task_execution_role_arn" {
  value = aws_iam_role.task_execution_role.arn
}