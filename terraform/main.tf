data "aws_caller_identity" "current" {}

module "networking" {
  source       = "./modules/networking"
  vpc_cidr     = "10.0.0.0/24"
  public_cidrs = ["10.0.0.0/25", "10.0.0.128/25"]
}

module "ecrs" {
  source     = "./modules/ecr"
  for_each   = toset(var.container_images)
  image_name = each.key
}

module "ecs_cluster" {
  source = "./modules/ecs/cluster"
}

module "ecs_task_definitions" {
  source                     = "./modules/ecs/task-definition"
  for_each                   = toset(var.container_images)
  task_name                  = each.key
  execution_role_arn         = module.ecs_cluster.task_execution_role_arn
  container_definitions_path = "${abspath(path.root)}/../${each.key}/taskdef.json"
  ecr_repository_url         = module.ecrs[each.key].repository_url
}

module "target_groups" {
  for_each    = toset(var.container_images)
  source      = "./modules/routing/target-group"
  vpc_id      = module.networking.vpc_id
  target_port = 3000
}

module "ecs_services" {
  source              = "./modules/ecs/service"
  for_each            = toset(var.container_images)
  depends_on          = [module.alb]
  name                = each.key
  cluster_id          = module.ecs_cluster.id
  task_definition_arn = module.ecs_task_definitions[each.key].arn
  target_group_arn    = module.target_groups[each.key].arn
  container_port      = 3000
  desired_count       = 2
}

module "alb" {
  source            = "./modules/routing/alb"
  vpc_id            = module.networking.vpc_id
  instance_type     = "t2.micro"
  subnet_ids        = module.networking.public_subnets_ids
  ecs_cluster_name  = module.ecs_cluster.id
  target_group_arns = [for target_group in module.target_groups : target_group.arn]
}

resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket        = "tf-sample-codepipeline-artifacts"
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "Terraform sample codepipeline artifact store"
  }
}

module "codebuild_role" {
  source              = "./modules/codebuild/role"
  artifact_bucket_arn = aws_s3_bucket.codepipeline_artifacts.arn
}

module "codebuilds" {
  source             = "./modules/codebuild/project"
  for_each           = toset(var.container_images)
  image_name         = each.key
  repository_url     = module.ecrs[each.key].repository_url
  service_role_arn   = module.codebuild_role.arn
  account_id         = data.aws_caller_identity.current.id
  region             = var.aws_region
  dockerhub_username = var.dockerhub_username
  dockerhub_password = var.dockerhub_password
}

module "codepipeline" {
  source              = "./modules/codepipeline"
  github_repo_id      = "MxGutierrez/terraform-sample"
  github_branch_name  = "master"
  ecs_cluster_id      = module.ecs_cluster.id
  artifact_bucket_arn = aws_s3_bucket.codepipeline_artifacts.arn
  artifact_bucket_id  = aws_s3_bucket.codepipeline_artifacts.id
  images = { for image in var.container_images : image => {
    name                 = image
    codebuild_project_id = module.codebuilds[image].id
    ecs_service_id       = module.ecs_services[image].id
  } }
}

