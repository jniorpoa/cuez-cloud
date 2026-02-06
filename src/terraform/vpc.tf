################################################################################
# Cuez Cloud - VPC Configuration
#
# Padrão de subnets LiveMode:
#   prod-public-a  = 10.15.0.0/24  (sa-east-1a)
#   prod-public-b  = 10.15.1.0/24  (sa-east-1b) — reservado
#   prod-public-c  = 10.15.2.0/24  (sa-east-1c) — reservado
#   prod-private-a = 10.15.10.0/24 (sa-east-1a) — reservado
################################################################################

# VPC Principal
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "prod-vpc"
  }
}

# Subnet Pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-public-a"
    Type = "Public"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "prod-igw"
  }
}

# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "prod-public-rt"
  }
}

# Associação Route Table com Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
