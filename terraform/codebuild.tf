resource "aws_iam_role" "codebuild" {
  name = "terraform-sample-codebuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild" {
    role = aws_iam_role.codebuild.id

    policy = <<POLICY
{
    "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
            ]
        }
    ]
}
POLICY
}

resource "aws_codebuild_project" "codebuild" {
    name = "terraform-sample-codebuild"
    service_role = aws_iam_role.codebuild.arn

    artifacts {
        type = "CODEPIPELINE"
    }

    source {
        type = "CODEPIPELINE"
        buildspec = "buildspec.yml"
    }

    environment {
        compute_type = "BUILD_GENERAL1_SMALL"
        image = "aws/codebuild/standard:3.0"
        type = "LINUX_CONTAINER"

        environment_variable {
            name = "AWS_TEST"
            value = "pruebaaaa"
        }
    }
}