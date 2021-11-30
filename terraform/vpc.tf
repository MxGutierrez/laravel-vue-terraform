locals {
  vpc_cidr       = "10.0.0.0/24"
  public_subnets = ["10.0.0.0/27", "10.0.0.32/27"]
  app_subnets    = ["10.0.0.128/26", "10.0.0.192/26"]
  db_subnets     = ["10.0.0.64/27", "10.0.0.96/27"]
}

resource "aws_vpc" "vpc" {
  cidr_block = local.vpc_cidr

  # Enable DNS support for service discovery
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tf-sample-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "tf-sample-igw"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.publics[0].id

  tags = {
    Name = "nat-gw"
  }
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "tf-sample-public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "tf-sample-private-route-table"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "publics" {
  count                   = length(local.public_subnets)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.public_subnets[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-sample-public-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(local.public_subnets)
  subnet_id      = aws_subnet.publics[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "apps" {
  count             = length(local.app_subnets)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.app_subnets[count.index]

  tags = {
    Name = "tf-sample-app-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "app" {
  count          = length(local.app_subnets)
  subnet_id      = aws_subnet.apps[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_subnet" "dbs" {
  count             = length(local.db_subnets)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.db_subnets[count.index]

  tags = {
    Name = "tf-sample-db-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "db" {
  count          = length(local.db_subnets)
  subnet_id      = aws_subnet.dbs[count.index].id
  route_table_id = aws_route_table.private.id
}