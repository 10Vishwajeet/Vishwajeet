resource "aws_vpc" "vnet" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "tf-vpc"
  }
}

# =========================
# PUBLIC SUBNET
# =========================

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vnet.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_az
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# =========================
# PRIVATE SUBNET
# =========================

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vnet.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_az

  tags = {
    Name = "private-subnet"
  }
}

# =========================
# INTERNET GATEWAY
# =========================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vnet.id

  tags = {
    Name = "tf-igw"
  }
}

# =========================
# PUBLIC ROUTE TABLE
# =========================

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vnet.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# =========================
# PUBLIC ROUTE TABLE ASSOCIATION
# =========================

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# =========================
# ELASTIC IP
# =========================

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

# =========================
# NAT GATEWAY
# =========================

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-gateway"
  }
}

# =========================
# PRIVATE ROUTE TABLE
# =========================

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vnet.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-rt"
  }
}

# =========================
# PRIVATE ROUTE TABLE ASSOCIATION
# =========================

resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# =========================
# SECURITY GROUP
# =========================

resource "aws_security_group" "web_sg" {
  name   = "web-security-group"
  vpc_id = aws_vpc.vnet.id

  ingress {
    description = "SSH"

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"

    from_port   = 80
    to_port     = 80
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
    Name = "web-sg"
  }
}

# =========================
# PUBLIC EC2
# =========================

resource "aws_instance" "public_vm" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from Public Server" > /var/www/html/index.html
              EOF

  tags = {
    Name = "public-server"
  }
}

# =========================
# PRIVATE EC2
# =========================

resource "aws_instance" "private_vm" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "private-server"
  }
}

# =========================
# OUTPUTS
# =========================

output "public_ip" {
  value = aws_instance.public_vm.public_ip
}

output "private_ip" {
  value = aws_instance.private_vm.private_ip
}
