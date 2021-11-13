data "aws_caller_identity" "current" {}

module "networking" {
  source       = "./Networking"
  vpc_cidr     = "10.0.0.0/24"
  public_cidrs = ["10.0.0.0/25", "10.0.0.128/25"]
}

module "ecrs" {
  source     = "./ECR"
  for_each   = toset(var.container_images)
  image_name = each.key
}

module "ecs_cluster" {
  source = "./ECS/Cluster"
}

module "ecs_task_definitions" {
  source                     = "./ECS/TaskDefinition"
  for_each                   = toset(var.container_images)
  task_name                  = each.key
  execution_role_arn         = module.ecs_cluster.task_execution_role_arn
  container_definitions_path = "../${each.key}/taskdef.json"
  ecr_repository_url         = ecrs[each.key].repository_url
}

module "ecs_services" {
  source              = "./ECS/Service"
  for_each            = toset(var.container_images)
  name                = each.key
  cluster_id          = module.ecs_cluster.id
  task_definition_arn = module.ecs_task_definitions[each.key].arn
}
