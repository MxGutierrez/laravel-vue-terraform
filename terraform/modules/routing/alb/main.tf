data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

data "aws_ami" "amazon_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

resource "aws_security_group" "instance" {
  name   = "ecs-instances-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-traffic-from-alb"
  }
}

resource "aws_launch_configuration" "ecs_launch_config" {
  image_id             = "ami-078cbb92727dec530"
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [aws_security_group.instance.id]
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config"
  instance_type        = var.instance_type

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ag" {
  name                 = "asg"
  vpc_zone_identifier  = var.subnet_ids
  launch_configuration = aws_launch_configuration.ecs_launch_config.name

  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
}

resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB-sg"
  }
}

resource "aws_lb" "alb" {
  name               = "ecs-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "tf-sample-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arns[0]
  }
}

resource "aws_lb_listener_rule" "static" {
  count        = length(var.target_group_arns)
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = var.target_group_arns[count.index]
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
