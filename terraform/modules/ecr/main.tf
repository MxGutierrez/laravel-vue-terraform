resource "aws_ecr_repository" "ecr" {
  name  = var.image_name
}
