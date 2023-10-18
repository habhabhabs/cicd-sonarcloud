provider "aws" {
  region     = "ap-southeast-1"
  access_key = var.aws_access_key # inside aws_key.tf file (in .gitignore)
  secret_key = var.aws_secret_key # inside aws_key.tf file (in .gitignore)
}

resource "aws_instance" "public_ec2_frontend" {
  depends_on    = [aws_network_interface.public_frontend_eni, aws_security_group.public_sg]
  ami           = "ami-055d15d9cfddf7bd3"
  instance_type = "t3.micro"
  key_name      = "aws-keypair-alex"

  network_interface {
    network_interface_id = aws_network_interface.public_frontend_eni.id
    device_index         = 0
  }

  tags = {
    Name = "public_ec2_frontend"
  }
}

resource "aws_instance" "private_ec2_backend" {
  depends_on    = [aws_network_interface.private_backend_eni, aws_security_group.private_sg_backend]
  ami           = "ami-055d15d9cfddf7bd3"
  instance_type = "t3.micro"
  key_name      = "aws-keypair-alex"

  network_interface {
    network_interface_id = aws_network_interface.private_backend_eni.id
    device_index         = 0
  }

  tags = {
    Name = "private_ec2_backend"
  }
}

resource "aws_instance" "private_ec2_db" {
  depends_on    = [aws_network_interface.private_db_eni, aws_security_group.private_sg_backend]
  ami           = "ami-055d15d9cfddf7bd3"
  instance_type = "t3.micro"
  key_name      = "aws-keypair-alex"

  network_interface {
    network_interface_id = aws_network_interface.private_db_eni.id
    device_index         = 0
  }

  tags = {
    Name = "private_ec2_db"
  }
}

resource "aws_s3_bucket" "mynoncompliantbucket" {
  bucket = "mybucketname"

  tags = {
    "anycompany:cost-center" = "Accounting"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}