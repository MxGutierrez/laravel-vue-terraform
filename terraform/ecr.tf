resource "aws_ecr_repository" "ecrs" {
  for_each = toset(var.repositories)
  name     = each.key
}
