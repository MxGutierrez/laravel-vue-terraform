terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = var.aws_region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

resource "aws_vpc" "tf-vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "terraform-sample"
    }
}

resource "aws_ecr_repository" "tf-ecr" {
    name = "terraform-sample"
}