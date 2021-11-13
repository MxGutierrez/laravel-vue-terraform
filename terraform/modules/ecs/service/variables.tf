variable "name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "task_definition_arn" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "container_port" {
  type = number
}

variable "desired_count" {
  type    = number
  default = 1
}
