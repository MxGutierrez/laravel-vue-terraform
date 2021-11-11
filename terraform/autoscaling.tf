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

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = aws_vpc.tf_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "allow_tls"
  }
}

resource "aws_key_pair" "ec2" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpe3kMBxVVLes8rgo/oJlQGW4ibbDjmxPDUEiPoSkhLwZA8iNzaDFY2kTCgXz8je2nk4bSwnkXLvB+8l8eTrzHLPDpaxDj86RdoSifYd80OUd7IdmG7ITn4LrnYKZ/i1meZTwdSk6AA93iFxQV0bRPuB1bhrJA+P0vq14dvXLJycUkqPZlxUtDAi5O6WbBbjgLJqcB7jrLMrFRh6EOi49/J+xPvQIdf+Dk2R8CjDuTpJwoTNK7a8Z6vGRkpFDAfH6OY+VnxU10EtcuysXQZBBLG4caFNxI7/vgNfOYYYDJuLNzrNsuH07/ADRrCb+ys48d9tUtL39FwWw4/LOyJQcd maximiliano@lightit-maximiliano-desktop"
}

resource "aws_launch_configuration" "ecs_launch_config" {
  image_id             = "ami-078cbb92727dec530"
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  key_name             = aws_key_pair.ec2.id
  security_groups      = [aws_security_group.ecs_sg.id]
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.cluster.name} >> /etc/ecs/ecs.config"
  instance_type        = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "failure_analysis_ecs_asg" {
  name                 = "asg"
  vpc_zone_identifier  = [aws_subnet.public.id]
  launch_configuration = aws_launch_configuration.ecs_launch_config.name
  # load_balancers = [aws_elb.ecs.id]

  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
}

# resource "aws_lb_target_group" "codedeploy_production" {
#   name     = "codedeploy_production"
#   port     = 3000
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.tf_vpc.id
# }


# resource "aws_elb" "ecs" {
#   name               = "ecs-lb"
#   availability_zones = [aws_subnet.public.availability_zone, aws_subnet.public2.availability_zone]

#   listener {
#     instance_port     = 3000
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }

#   cross_zone_load_balancing   = true

#   tags = {
#     Name = "foobar-terraform-elb"
#   }
# }
