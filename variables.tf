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
