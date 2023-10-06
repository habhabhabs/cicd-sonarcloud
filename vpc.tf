# VPC definition
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my_vpc"
  }
}

# internet gateway
resource "aws_internet_gateway" "nat_gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_vpc-nat_gw"
  }
}

resource "aws_route_table" "internet_connection" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nat_gw.id
  }

  tags = {
    Name = "my_vpc-nat_gw-internet_connection"
  }
}

resource "aws_route_table_association" "internet_public_subnet" {
  depends_on     = [aws_subnet.public_subnet]
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.internet_connection.id
}

# public EIPs
resource "aws_eip" "public_eip" {
  depends_on                = [aws_internet_gateway.nat_gw, aws_network_interface.public_frontend_eni]
  vpc                       = true
  network_interface         = aws_network_interface.public_frontend_eni.id
  associate_with_private_ip = "10.0.1.100"
}

# VPC subnets
resource "aws_subnet" "public_subnet" {
  depends_on              = [aws_internet_gateway.nat_gw]
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "my_vpc-public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "my_vpc-private_subnet"
  }
}

# security groups
resource "aws_security_group" "public_sg" {
  vpc_id      = aws_vpc.my_vpc.id
  name        = "public_sg"
  description = "Public VPC Security Group"

  # allow ping from external
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
  }

  # allow ingress of port 22
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  # allow ingress of port 8080
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
  }

  # allow egress of all ports
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    Name        = "public_sg"
    Description = "Public VPC Security Group"
  }
}

resource "aws_security_group" "private_sg_backend" {
  vpc_id      = aws_vpc.my_vpc.id
  name        = "private_sg_backend"
  description = "Private VPC Security Group - Backend"

  # allow ping within subnet
  ingress {
    cidr_blocks = ["10.0.0.0/16"]
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
  }

  # allow ingress of port 22
  ingress {
    cidr_blocks = ["10.0.1.0/24"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  # allow ingress of port 3000
  ingress {
    cidr_blocks = ["10.0.1.0/24"]
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
  }

  # allow egress of all ports
  egress {
    cidr_blocks = ["10.0.2.101/32"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  # allow egress of port 3000
  egress {
    cidr_blocks = ["10.0.1.100/32"]
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
  }

  tags = {
    Name        = "private_sg_backend"
    Description = "Private VPC Security Group - Backend"
  }
}

resource "aws_security_group" "private_sg_db" {
  vpc_id      = aws_vpc.my_vpc.id
  name        = "private_sg_db"
  description = "Private VPC Security Group - Database"

  # allow ping within subnet
  ingress {
    cidr_blocks = ["10.0.0.0/16"]
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
  }

  # allow ingress of port 27017
  ingress {
    cidr_blocks = ["10.0.2.100/32"]
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
  }

  # allow ingress of port 22
  ingress {
    cidr_blocks = ["10.0.2.100/32"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  # allow egress of port 22
  egress {
    cidr_blocks = ["10.0.2.100/32"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  # allow egress of port 27017
  egress {
    cidr_blocks = ["10.0.2.100/32"]
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
  }

  tags = {
    Name        = "private_sg_db"
    Description = "Private VPC Security Group - Database"
  }
}


# public ENIs
resource "aws_network_interface" "public_frontend_eni" {
  subnet_id       = aws_subnet.public_subnet.id
  private_ips     = ["10.0.1.100"]
  security_groups = [aws_security_group.public_sg.id]

  tags = {
    Name = "my_vpc-public_subnet-frontend_eni"
  }
}

# private ENIs
resource "aws_network_interface" "private_backend_eni" {
  subnet_id       = aws_subnet.private_subnet.id
  private_ips     = ["10.0.2.100"]
  security_groups = [aws_security_group.private_sg_backend.id]

  tags = {
    Name = "my_vpc-private_subnet-backend_eni"
  }
}

resource "aws_network_interface" "private_db_eni" {
  subnet_id       = aws_subnet.private_subnet.id
  private_ips     = ["10.0.2.101"]
  security_groups = [aws_security_group.private_sg_db.id]

  tags = {
    Name = "my_vpc-private_subnet-db_eni"
  }
}

