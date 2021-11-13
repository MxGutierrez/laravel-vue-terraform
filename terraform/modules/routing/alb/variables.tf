variable "vpc_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ecs_cluster_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "target_group_arns" {
  type = list(string)
}
