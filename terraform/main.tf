terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "tf-practice-remote-backend"
    key = "tf-pracitce/state.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
    region = var.region
}

resource "aws_vpc" "cicd-tf-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "cicd-tf-subnet" {
  vpc_id     = aws_vpc.cicd-tf-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

resource "aws_internet_gateway" "cicd-tf-gw" {
  vpc_id = aws_vpc.cicd-tf-vpc.id

  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

resource "aws_default_route_table" "cicd-tf-rt" {
  default_route_table_id = aws_vpc.cicd-tf-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cicd-tf-gw.id
  }
  tags = {
    Name: "${var.env_prefix}-main-rtb"
  }
}


resource "aws_default_security_group" "cicd-tf-sg" {
  vpc_id = aws_vpc.cicd-tf-vpc.id

  ingress {
    protocol  = "TCP"
    from_port = 22
    to_port   = 22
    cidr_blocks = [var.my_ip , var.jenkins_ip]
  }

  ingress {
    protocol  = "TCP"
    from_port = 8000
    to_port   = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}

data "aws_ami" "aws-linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.9.20251110.1-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

resource "aws_instance" "tf-cicd-server" {
  ami = data.aws_ami.aws-linux.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.cicd-tf-subnet.id
  vpc_security_group_ids = [aws_default_security_group.cicd-tf-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = "tf-cicd-key"

  user_data = file("entry-script.sh")

  user_data_replace_on_change = true

  tags = {
    Name: "${var.env_prefix}-server"
  }
}

output "ec2-public-ip" {
  value = aws_instance.tf-cicd-server.public_ip
}











