locals {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_vpc" "argo" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name}-vpc"
    Project = var.project_name
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "argo" {
  vpc_id = aws_vpc.argo.id

  tags = {
    Name = "${local.name}-igw"
    Project = var.project_name
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.argo.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public-${count.index + 1}"
    Project = var.project_name
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.argo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.argo.id
  }

  tags = {
    Name = "${local.name}-public-rt"
    Project = var.project_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
