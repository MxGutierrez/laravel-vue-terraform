# resource "aws_iam_role" "codedeploy" {
#   name = "codedeploy"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "codedeploy.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS" {
#   policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
#   role       = aws_iam_role.codedeploy.name
# }

# resource "aws_codedeploy_app" "tf_sample" {
#   compute_platform = "ECS"
#   name             = "terraform-sample-codedeploy"
# }

# resource "aws_codedeploy_deployment_group" "tf_sample" {
#   app_name               = aws_codedeploy_app.tf_sample.name
#   deployment_group_name  = "tf-sample-deployment-group"
#   deployment_config_name = "CodeDeployDefault.OneAtATime" // Default
#   service_role_arn       = aws_iam_role.codedeploy.arn

#   auto_rollback_configuration {
#     enabled = true
#     events  = ["DEPLOYMENT_FAILURE"]
#   }
# }
