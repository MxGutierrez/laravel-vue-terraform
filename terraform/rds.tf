resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.dbs[*].id

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_task.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_db_instance" "db" {
  name                   = var.db_name
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = 13.4
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  multi_az               = true

  tags = {
    Name = "tf-sample-db"
  }
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name                    = "tfsample/prod/postgres"
  recovery_window_in_days = 0 # amount of days a secret is scheduled until real deletion
}

resource "aws_secretsmanager_secret_version" "rds_secret" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = aws_db_instance.db.username
    password = aws_db_instance.db.password
  })
}
