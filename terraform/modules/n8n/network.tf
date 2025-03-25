# VPC and Network Configuration
resource "aws_vpc" "n8n_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_subnet" "n8n_subnet" {
  vpc_id                  = aws_vpc.n8n_vpc.id
  cidr_block             = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-subnet"
  })
}

resource "aws_internet_gateway" "n8n_igw" {
  vpc_id = aws_vpc.n8n_vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_route_table" "n8n_rt" {
  vpc_id = aws_vpc.n8n_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.n8n_igw.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-rt"
  })
}

resource "aws_route_table_association" "n8n_rta" {
  subnet_id      = aws_subnet.n8n_subnet.id
  route_table_id = aws_route_table.n8n_rt.id
}