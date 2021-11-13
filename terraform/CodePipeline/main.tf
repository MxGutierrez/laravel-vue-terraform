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
        "${var.artifact_bucket_arn}",
        "${var.artifact_bucket_arn}/*"
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
    location = var.artifact_bucket_arn
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
        FullRepositoryId = var.github_repo_id
        BranchName       = var.github_branch_name
      }
    }
  }

  stage {
    name = "Build"

    dynamic "action" {
      count = length(var.images)
      content {
        name             = "Build-${var.images[count.index].name}"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        output_artifacts = ["${var.images[count.index].name}_build_output"]
        version          = "1"

        configuration = {
          ProjectName = var.images[count.index].codebuild_project_id
        }
      }
    }
  }

  stage {
    name = "Deploy"

    dynamic "action" {
      count = length(var.images)
      content {

        name     = "Deploy-${var.images[count.index].name}"
        category = "Deploy"
        owner    = "AWS"
        provider = "ECS"
        version  = 1

        configuration = {
          ClusterName = var.ecs_cluster_id
          ServiceName = var.images[count.index].ecs_service_id
          FileName    = "imagedefinitions.json"
        }

        input_artifacts = ["${var.images[count.index].name}_build_output"]
      }
    }
  }
}

