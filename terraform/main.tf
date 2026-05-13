terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # If you configured a named profile above, add: profile = "cs312"
}

resource "aws_vpc" "cs312" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "cs312-vpc"
  }
}

resource "aws_subnet" "cs312_public" {
  vpc_id                  = aws_vpc.cs312.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cs312-public-subnet"
  }
}

resource "aws_internet_gateway" "cs312_igw" {
  vpc_id = aws_vpc.cs312.id

  tags = {
    Name = "cs312-igw"
  }
}

resource "aws_route_table" "cs312_public_rt" {
  vpc_id = aws_vpc.cs312.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cs312_igw.id
  }

  tags = {
    Name = "cs312-public-rt"
  }
}

resource "aws_route_table_association" "cs312_public_rta" {
  subnet_id      = aws_subnet.cs312_public.id
  route_table_id = aws_route_table.cs312_public_rt.id
}

# Security Group for EC2 Instance
resource "aws_security_group" "minecraft" {
  name		= "cs312-minecraft-sg"
  description	= "Allow SSH on port 22, allow all TCP on 25565"
  vpc_id 	= aws_vpc.cs312.id

  ingress {
    description	= "SSH"
    from_port	= 22
    to_port	= 22
    protocol	= "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }

  ingress {
    description	= "Minecraft Port"
    from_port	= 25565
    to_port	= 25565
    protocol	= "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port	= 0
    to_port	= 0
    protocol	= "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cs312-minecraft-sg"
  }
}

#server instance
resource "aws_instance" "minecraft" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.minecraft.id]
  iam_instance_profile   = "LabInstanceProfile"
  subnet_id 		 = aws_subnet.cs312_public.id
  tags = {
    Name = "cs312-tf-minecraft"
  }
}

# ECR repository for the CI/CD pipeline in Lab 6
resource "aws_ecr_repository" "minecraft" {
  name                 = "cs312-minecraft-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

#S3 bucket for world data 
resource "aws_s3_bucket" "world" { 
  bucket	= "piperga-minecraft"

  tags = {
    Name	= "Minecraft World Data"
  }
}
     
resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tftpl", {
    ip = aws_instance.minecraft.public_ip
  })
  filename = pathexpand("~/school/cs312/ops3/ansible/inventory")
}

	
