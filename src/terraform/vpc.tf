################################################################################
# Cuez Cloud - VPC Configuration (Multi-Region)
#
# São Paulo (sa-east-1):  10.15.11.0/24 — vMix
# Virginia (us-east-1):   10.15.1.0/24  — Gateway + Automator
# VPC Peering: cross-region communication
################################################################################

################################################################################
# VPC — São Paulo (sa-east-1)
################################################################################
resource "aws_vpc" "saopaulo" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "prod-vpc-sp"
    Region = "sa-east-1"
  }
}

resource "aws_subnet" "saopaulo_public" {
  vpc_id                  = aws_vpc.saopaulo.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-public-sp-a"
    Type = "Public"
  }
}

resource "aws_internet_gateway" "saopaulo" {
  vpc_id = aws_vpc.saopaulo.id

  tags = {
    Name = "prod-igw-sp"
  }
}

resource "aws_route_table" "saopaulo_public" {
  vpc_id = aws_vpc.saopaulo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.saopaulo.id
  }

  route {
    cidr_block                = var.virginia_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.sp_to_virginia.id
  }

  tags = {
    Name = "prod-public-rt-sp"
  }
}

resource "aws_route_table_association" "saopaulo_public" {
  subnet_id      = aws_subnet.saopaulo_public.id
  route_table_id = aws_route_table.saopaulo_public.id
}

################################################################################
# VPC — Virginia (us-east-1)
################################################################################
resource "aws_vpc" "virginia" {
  provider             = aws.virginia
  cidr_block           = var.virginia_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "prod-vpc-va"
    Region = "us-east-1"
  }
}

resource "aws_subnet" "virginia_public" {
  provider                = aws.virginia
  vpc_id                  = aws_vpc.virginia.id
  cidr_block              = var.virginia_subnet_cidr
  availability_zone       = var.virginia_az
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-public-va-a"
    Type = "Public"
  }
}

resource "aws_internet_gateway" "virginia" {
  provider = aws.virginia
  vpc_id   = aws_vpc.virginia.id

  tags = {
    Name = "prod-igw-va"
  }
}

resource "aws_route_table" "virginia_public" {
  provider = aws.virginia
  vpc_id   = aws_vpc.virginia.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.virginia.id
  }

  route {
    cidr_block                = var.vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.sp_to_virginia.id
  }

  tags = {
    Name = "prod-public-rt-va"
  }
}

resource "aws_route_table_association" "virginia_public" {
  provider       = aws.virginia
  subnet_id      = aws_subnet.virginia_public.id
  route_table_id = aws_route_table.virginia_public.id
}

################################################################################
# VPC Peering — São Paulo ↔ Virginia
################################################################################
resource "aws_vpc_peering_connection" "sp_to_virginia" {
  vpc_id      = aws_vpc.saopaulo.id
  peer_vpc_id = aws_vpc.virginia.id
  peer_region = "us-east-1"
  auto_accept = false

  tags = {
    Name = "prod-peering-sp-va"
    Side = "requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "virginia_accept" {
  provider                  = aws.virginia
  vpc_peering_connection_id = aws_vpc_peering_connection.sp_to_virginia.id
  auto_accept               = true

  tags = {
    Name = "prod-peering-sp-va"
    Side = "accepter"
  }
}
