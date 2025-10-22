# Simple Terraform Code to Deploy EC2 - Beginner's Explanation

## 🎯 What We're Building

## A basic web server on AWS that you can access from the internet.

## 📁 File Structure

```bash
terraform-ec2/
├── main.tf          # Main configuration
├── variables.tf     # Input variables
├── outputs.tf       # What to show after deployment
└── terraform.tfvars # Your specific values
```

## 📄 File 1: main.tf (The Main Configuration)
```bash
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
  user_data = <<-EOF
              #!/bin/bash
              # Update all packages
              yum update -y
              
              # Install Apache web server
              yum install -y httpd
              
              # Start Apache and make it start automatically
              systemctl start httpd
              systemctl enable httpd
              
              # Create a simple web page
              echo "<h1>Hello from my Terraform server!</h1>" > /var/www/html/index.html
              echo "<p>Server is running successfully!</p>" >> /var/www/html/index.html
              EOF

  tags = {
    Name = var.server_name
  }
}
```

## 📄 File 2: variables.tf (Input Settings)
```bash
# variables.tf - These are like settings you can change

# Which AWS region to use
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"  # Virginia region (usually cheapest)
}

# What size server to create
variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t2.micro"   # Free tier eligible
}

# Name for your server
variable "server_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "My-Web-Server"
}

# SSH key name (you must create this in AWS Console first)
variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
  # No default - you must provide this
}
```

## 📄 File 3: outputs.tf (What to Show After Creation)
```bash
# outputs.tf - Information displayed after deployment

# Show the server's public IP address
output "instance_public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

# Show the website URL
output "website_url" {
  description = "URL to access the website"
  value       = "http://${aws_instance.web_server.public_ip}"
}

# Show the SSH command to connect
output "ssh_command" {
  description = "Command to SSH into the server"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.web_server.public_ip}"
}

# Show the instance ID
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}
```

## 📄 File 4: terraform.tfvars (Your Personal Settings)
```bash
# terraform.tfvars - Your specific values

# AWS region where you want to deploy
aws_region = "us-east-1"

# Size of your server
instance_type = "t2.micro"

# Name for your server
server_name = "My-First-Server"

# Your SSH key name (IMPORTANT: Create this in AWS Console first!)
key_name = "my-aws-key"  # Replace with your actual key pair name
```

## 🚀 Step-by-Step Deployment

### Step 1: Prerequisites

```bash
# 1. Install Terraform
# 2. Install AWS CLI
# 3. Configure AWS credentials
aws configure

# 4. Create SSH key pair in AWS Console (EC2 > Key Pairs)
```

### Step 2: Create Your Files

```bash
# Create project directory
mkdir terraform-ec2
cd terraform-ec2

# Create the 4 files above with the code provided
# main.tf, variables.tf, outputs.tf, terraform.tfvars
```

### Step 3: Deploy
```bash
# Initialize Terraform (downloads AWS provider)
terraform init

# See what will be created
terraform plan

# Create the resources
terraform apply
```

### Step 4: See Results

After terraform apply completes, you'll see:
```bash
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-0123456789abcdef0"
instance_public_ip = "54.123.45.67"
ssh_command = "ssh -i my-aws-key.pem ec2-user@54.123.45.67"
website_url = "http://54.123.45.67"
```

## 🎯 What Each Part Does (Simple Explanation)
### 1. Provider Block
```bash
provider "aws" {
  region = var.aws_region
}
```
## What it does: "Hey Terraform, we want to use AWS, and deploy in this region"

### 2. Data Source
```bash
data "aws_ami" "amazon_linux" {
  most_recent = true
  # ...
}
```
## What it does: "Find me the newest Amazon Linux server image to use"

### 3. Security Group
```bash
resource "aws_security_group" "web_sg" {
  # Allow SSH and HTTP
}
```

## What it does: "Create firewall rules: allow SSH (port 22) and web traffic (port 80)"

### 4. EC2 Instance
```bash
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  # ...
}
```

## What it does: "Create a server using that image, make it this size, apply those firewall rules"

### 5. User Data Script
```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
```

## What it does: "When the server starts, update it and install a web server"


## 🔧 Common Customizations

### Change Server Size
```bash
# In terraform.tfvars
instance_type = "t3.small"  # Bigger server (costs more)
```

### Add Custom Web Content

```bash
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
```

### Deploy Multiple Servers
```bash
# In main.tf
resource "aws_instance" "web_server" {
  count = 2  # Creates 2 servers
  # ... rest of config
  
  tags = {
    Name = "${var.server_name}-${count.index + 1}"
  }
}
```

## 🧹 Cleanup (Important!)
```bash
# When you're done, delete everything to avoid charges
terraform destroy
```

## 📊 What You Get

## After running this code:

###   ✅ 1 Web Server running Amazon Linux
###   ✅ Apache web server installed and running
###   ✅ Security group allowing web and SSH access
###   ✅ Public IP address to access your server
###   ✅ Simple web page showing "Hello from my Terraform server!"


### Total AWS resources created: 2 (1 EC2 instance + 1 Security Group)
### Estimated monthly cost: ~$8-10 (if running 24/7 with t2.micro)

### This is the simplest possible setup to get a web server running with Terraform! 🎉






