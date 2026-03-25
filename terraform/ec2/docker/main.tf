terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------- Auto-detect deployer's public IP ----------
data "external" "my_ip" {
  program = ["bash", "-c", "echo \"{\\\"ip\\\": \\\"$(curl -s checkip.amazonaws.com)/32\\\"}\""]
}

locals {
  my_cidr = data.external.my_ip.result["ip"]
}

# ---------- Latest Amazon Linux 2023 AMI ----------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------- VPC (default) ----------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------- Security Group ----------
resource "aws_security_group" "corndog" {
  name_prefix = "corndog-"
  description = "Corndog demo - HTTP + SSH"
  vpc_id      = data.aws_vpc.default.id

  # App UI
  ingress {
    description = "Corndog Web UI"
    from_port   = 4200
    to_port     = 4200
    protocol    = "tcp"
    cidr_blocks = [local.my_cidr]
  }

  # SSH (only when a key pair is provided)
  dynamic "ingress" {
    for_each = var.ssh_key_name != "" ? [1] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [local.my_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "corndog-demo" }
}

# ---------- IAM role (SSM access so you can connect without SSH key) ----------
resource "aws_iam_role" "corndog" {
  name_prefix = "corndog-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.corndog.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "corndog" {
  name_prefix = "corndog-"
  role        = aws_iam_role.corndog.name
}

# ---------- EC2 Instance ----------
resource "aws_instance" "corndog" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name != "" ? var.ssh_key_name : null
  vpc_security_group_ids = [aws_security_group.corndog.id]
  subnet_id              = data.aws_subnets.default.ids[0]
  iam_instance_profile   = aws_iam_instance_profile.corndog.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    dd_api_key   = var.dd_api_key
    dd_site      = var.dd_site
    dd_env       = var.dd_env
    github_token = var.github_token
    repo_url     = var.repo_url
    repo_branch  = var.repo_branch
  }))

  tags = {
    Name = "corndog-demo"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
