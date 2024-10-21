provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "ts-vpc" {
  cidr_block = "192.169.0.0/16"

  tags = {
    Name = "ts-vpc" 
  }
}

resource "aws_subnet" "ts-subnet" {
  vpc_id            = aws_vpc.main.id  
  cidr_block        = "192.169.1.0/24" 
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ts-subnet"
  }
}

resource "aws_subnet" "ts_private_subnet" {
  vpc_id            = aws_vpc.ts-vpc.id
  cidr_block        = "192.169.2.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "ts-private-subnet"
  }
}

resource "aws_internet_gateway" "ts-igw" {
  vpc_id = aws_vpc.ts-vpc.id

  tags = {
    Name = "ts-igw"
  }
}

resource "aws_eip" "ts_nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "ts_nat_gateway" {
  allocation_id = aws_eip.ts_nat_eip.id
  subnet_id     = aws_subnet.ts_subnet.id

  tags = {
    Name = "ts-nat-gateway"
  }
}

resource "aws_route_table" "ts-public_rt" {
  vpc_id = aws_vpc.ts-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ts-igw.id
  }

  tags = {
    Name = "ts-public-route-table"
  }
}

resource "aws_route_table_association" "ts_public_rta" {
  subnet_id      = aws_subnet.ts_subnet.id
  route_table_id = aws_route_table.ts_public_rt.id
}

resource "aws_route_table" "ts_private_rt" {
  vpc_id = aws_vpc.ts-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ts_nat_gateway.id
  }

  tags = {
    Name = "ts-private-route-table"
  }
}

resource "aws_route_table_association" "ts_private_rta" {
  subnet_id      = aws_subnet.ts_private_subnet.id
  route_table_id = aws_route_table.ts_private_rt.id
}

resource "aws_security_group" "ts-sg" {
  vpc_id = aws_vpc.ts-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
	  from_port   = 8080
	  to_port     = 8080
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
	
	ingress {
	  from_port   = 3306
	  to_port     = 3306
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
	
	ingress {
	  from_port   = 80
	  to_port     = 80
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
	
	ingress {
	  from_port   = 443
	  to_port     = 443
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
	
	ingress {
	  from_port   = 5000
	  to_port     = 5000
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
	
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ts-sg"
  }
}

resource "aws_instance" "ts_backend" {
	count         = 2
  ami           = "ami-062cf18d655c0b1e8"
  instance_type = "t2.medium"
  key_name      = "?"  
	subnet_id     = aws_subnet.ts_private_subnet.id
  vpc_security_group_ids = [aws_security_group.ts-sg.id]
  associate_public_ip_address = false

  tags = {
    Name = "TS Backend ${count.index + 1}"
  }
}

resource "aws_instance" "ts_frontend" {
	count         = 2
  ami           = "ami-062cf18d655c0b1e8"
  instance_type = "t2.medium"
  key_name      = "?"  
  subnet_id     = aws_subnet.ts-subnet.id
  vpc_security_group_ids = [aws_security_group.ts-sg.id]

  tags = {
    Name = "TS Frontend ${count.index + 1}"
  }
}

resource "aws_instance" "ts_ai" {
	count         = 2
  ami           = "ami-062cf18d655c0b1e8"
  instance_type = "t2.medium"
  key_name      = "?"
  subnet_id     = aws_subnet.ts-subnet.id
  vpc_security_group_ids = [aws_security_group.ts-sg.id]

  tags = {
    Name = "TS AI ${count.index + 1}"
  }
}

resource "aws_instance" "ts_jenkins" {
  ami           = "ami-062cf18d655c0b1e8"
  instance_type = "t2.medium"
  key_name      = "?"
  subnet_id     = aws_subnet.ts-subnet.id
  vpc_security_group_ids = [aws_security_group.ts-sg.id]

  tags = {
    Name = "TS Jenkins"
  }
}

output "instance_ips" {
  value = {
    backend  = [for i in aws_instance.ts_backend : i.private_ip]
    frontend = [for i in aws_instance.ts_frontend : i.public_ip]
    ai       = [for i in aws_instance.ts_ai : i.public_ip]
    jenkins  = aws_instance.ts_jenkins.public_ip
  }
}

