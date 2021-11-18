resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket        = "tf-sample-codepipeline-artifacts"
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "Terraform-sample-codepipeline-artifacts"
  }
}

resource "aws_codestarconnections_connection" "github_app" {
  name          = "github-connection"
  provider_type = "GitHub"
}

resource "aws_iam_role" "codepipeline" {
  name = "terraform-sample-codepipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_artifacts.arn}",
        "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${aws_codestarconnections_connection.github_app.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_fullaccess" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_codepipeline" "pipeline" {
  name     = "terraform-sample-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github_app.arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "backend-build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["backend_build_output"]
      version          = 1

      configuration = {
        ProjectName = aws_codebuild_project.backend.id
      }
    }
    action {
      name             = "frontend-build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["frontend_build_output"]
      version          = 1

      configuration = {
        ProjectName = aws_codebuild_project.frontend.id
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = "backend-deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "ECS"
      version  = 1

      configuration = {
        ClusterName = aws_ecs_cluster.cluster.id
        ServiceName = aws_ecs_service.backend.id
        FileName    = "imagedefinitions.json"
      }

      input_artifacts = ["backend_build_output"]
    }

    action {
      name     = "frontend-deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "ECS"
      version  = 1

      configuration = {
        ClusterName = aws_ecs_cluster.cluster.id
        ServiceName = aws_ecs_service.frontend.id
        FileName    = "imagedefinitions.json"
      }

      input_artifacts = ["frontend_build_output"]
    }
  }
}

