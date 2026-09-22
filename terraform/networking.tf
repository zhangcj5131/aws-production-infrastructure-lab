# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = false

  tags = {
    Name = "aws-prod-lab-vpc"
  }
}


# ============================================================
# Public Subnets
# ============================================================

resource "aws_subnet" "public_a1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "public-subnet-a1"
  }
}

resource "aws_subnet" "public_b1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "public-subnet-b1"
  }
}


# ============================================================
# Private Application Subnets
# ============================================================

resource "aws_subnet" "private_app_a2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-app-subnet-a2"
  }
}

resource "aws_subnet" "private_app_b2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-app-subnet-b2"
  }
}


# ============================================================
# Private Data Subnets
# ============================================================

resource "aws_subnet" "private_data_a3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-data-subnet-a3"
  }
}

resource "aws_subnet" "private_data_b3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.6.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-data-subnet-b3"
  }
}


# ============================================================
# Internet Gateway
# ============================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "aws-prod-lab-igw"
  }
}


# ============================================================
# Elastic IPs for NAT Gateways
# ============================================================

resource "aws_eip" "nat_a" {
  domain = "vpc"
}

resource "aws_eip" "nat_b" {
  domain = "vpc"
}


# ============================================================
# NAT Gateways
# ============================================================

resource "aws_nat_gateway" "a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a1.id

  tags = {
    Name = "nat-gateway-a"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b1.id

  tags = {
    Name = "nat-gateway-b"
  }

  depends_on = [aws_internet_gateway.main]
}


# ============================================================
# Public Route Table
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_a1" {
  subnet_id      = aws_subnet.public_a1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b1" {
  subnet_id      = aws_subnet.public_b1.id
  route_table_id = aws_route_table.public.id
}


# ============================================================
# Private Application Route Table A
# ============================================================

resource "aws_route_table" "private_app_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.a.id
  }

  tags = {
    Name = "private-app-rt-a"
  }
}

resource "aws_route_table_association" "private_app_a2" {
  subnet_id      = aws_subnet.private_app_a2.id
  route_table_id = aws_route_table.private_app_a.id
}


# ============================================================
# Private Application Route Table B
# ============================================================

resource "aws_route_table" "private_app_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.b.id
  }

  tags = {
    Name = "private-app-rt-b"
  }
}

resource "aws_route_table_association" "private_app_b2" {
  subnet_id      = aws_subnet.private_app_b2.id
  route_table_id = aws_route_table.private_app_b.id
}


# ============================================================
# Private Data Route Table
# ============================================================

resource "aws_route_table" "private_data" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-data-rt"
  }
}

resource "aws_route_table_association" "private_data_a3" {
  subnet_id      = aws_subnet.private_data_a3.id
  route_table_id = aws_route_table.private_data.id
}

resource "aws_route_table_association" "private_data_b3" {
  subnet_id      = aws_subnet.private_data_b3.id
  route_table_id = aws_route_table.private_data.id
}