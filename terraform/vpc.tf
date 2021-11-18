locals {
  vpc_cidr            = "10.0.0.0/24"
  public_subnet_cidrs = ["10.0.0.0/25", "10.0.0.128/25"]
}

resource "aws_vpc" "vpc" {
  cidr_block = local.vpc_cidr

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

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "tf-sample-public-route-table"
  }
}

resource "aws_route" "route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets" {
  count                   = length(local.public_subnet_cidrs)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-sample-public-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "public_subnet" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}