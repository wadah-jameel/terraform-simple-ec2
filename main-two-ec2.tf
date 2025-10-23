# main.tf - This is where we define what to create

# Tell Terraform we want to use AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS (which region to use)
provider "aws" {
  region = var.aws_region  # We'll define this in variables.tf
}

# Get the latest Amazon Linux image
# Think of this as asking "What's the newest version?"
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create a security group (like firewall rules)
# This controls who can access our server and how
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow web and SSH traffic"

  # Allow SSH (port 22) so we can log into the server
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere (not recommended for production)
  }

  # Allow HTTP (port 80) so people can visit our website
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere
  }

  # Allow all outbound traffic (server can reach internet)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-security-group"
  }
}

# Create the actual server (EC2 instance)
resource "aws_instance" "web_server" {
  count = 2  # Creates 2 servers
  # Use the Amazon Linux image we found above
  ami           = data.aws_ami.amazon_linux.id
  
  # Size of the server (t2.micro is free tier eligible)
  instance_type = var.instance_type
  
  # Which SSH key to use (you need to create this in AWS first)
  key_name      = var.key_name
  
  # Apply our security group (firewall rules)
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Script that runs when the server starts up
  # This installs and starts a web server
  # In main.tf, modify user_data:
user_data = <<-EOF
            #!/bin/bash
            yum update -y
            yum install -y httpd
            systemctl start httpd
            systemctl enable httpd
            
            # Your custom content
            echo "<h1>Welcome to My Company!</h1>" > /var/www/html/index.html
            echo "<p>This is our web server</p>" >> /var/www/html/index.html
            EOF
  tags = {
    Name = "${var.server_name}-${count.index + 1}"
  }
}
