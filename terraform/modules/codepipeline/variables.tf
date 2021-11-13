variable "artifact_bucket_arn" {
  type = string
}

variable "github_repo_id" {
  type = string
}

variable "github_branch_name" {
  type = string
}

variable "ecs_cluster_id" {
  type = string
}

variable "images" {
  type = list(object({
    name                 = string
    codebuild_project_id = string
    ecs_service_id       = string
  }))
}
