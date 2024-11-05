provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "ts-vpc" {
  cidr_block = "192.169.0.0/16"

  tags = {
    Name = "ts-vpc" 
  }
}

# Subnets for Availability Zone A
resource "aws_subnet" "ts-public-subnet-a" {
  vpc_id            = aws_vpc.ts-vpc.id  
  cidr_block        = "192.169.1.0/24" 
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ts-public-subnet-a"
  }
}

resource "aws_subnet" "ts-private-subnet-a" {
  vpc_id            = aws_vpc.ts-vpc.id
  cidr_block        = "192.169.2.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "ts-private-subnet-a"
  }
}

# Subnets for Availability Zone B
resource "aws_subnet" "ts-public-subnet-b" {
  vpc_id            = aws_vpc.ts-vpc.id  
  cidr_block        = "192.169.3.0/24" 
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "ts-public-subnet-b"
  }
}

resource "aws_subnet" "ts-private-subnet-b" {
  vpc_id            = aws_vpc.ts-vpc.id
  cidr_block        = "192.169.4.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "ts-private-subnet-b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ts-igw" {
  vpc_id = aws_vpc.ts-vpc.id

  tags = {
    Name = "ts-igw"
  }
}

# NAT Gateway in public subnet in AZ A
resource "aws_eip" "ts-nat-eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "ts-nat-gateway" {
  allocation_id = aws_eip.ts-nat-eip.id
  subnet_id     = aws_subnet.ts-public-subnet-a.id

  tags = {
    Name = "ts-nat-gateway"
  }
}

# Public Route Tables
resource "aws_route_table" "ts-public-rt-a" {
  vpc_id = aws_vpc.ts-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ts-igw.id
  }

  tags = {
    Name = "ts-public-route-table-a"
  }
}

resource "aws_route_table" "ts-public-rt-b" {
  vpc_id = aws_vpc.ts-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ts-igw.id
  }

  tags = {
    Name = "ts-public-route-table-b"
  }
}

# Private Route Tables
resource "aws_route_table" "ts-private-rt-a" {
  vpc_id = aws_vpc.ts-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ts-nat-gateway.id
  }

  tags = {
    Name = "ts-private-route-table-a"
  }
}

resource "aws_route_table" "ts-private-rt-b" {
  vpc_id = aws_vpc.ts-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ts-nat-gateway.id
  }

  tags = {
    Name = "ts-private-route-table-b"
  }
}

# Route Table Associations
resource "aws_route_table_association" "ts-public-rta-a" {
  subnet_id      = aws_subnet.ts-public-subnet-a.id
  route_table_id = aws_route_table.ts-public-rt-a.id
}

resource "aws_route_table_association" "ts-public-rta-b" {
  subnet_id      = aws_subnet.ts-public-subnet-b.id
  route_table_id = aws_route_table.ts-public-rt-b.id
}

resource "aws_route_table_association" "ts-private-rta-a" {
  subnet_id      = aws_subnet.ts-private-subnet-a.id
  route_table_id = aws_route_table.ts-private-rt-a.id
}

resource "aws_route_table_association" "ts-private-rta-b" {
  subnet_id      = aws_subnet.ts-private-subnet-b.id
  route_table_id = aws_route_table.ts-private-rt-b.id
}