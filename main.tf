# terraform {
#   backend "s3" {
#     bucket = "dwn-terraform-tf-state"
#     key    = "terraform-state/terraform.tfstate"
#     region = "us-east-2"
#   }
# }


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}

# Create VPC
resource "aws_vpc" "dwn-vpc" {
  cidr_block       = var.vpc_prefix
  
  tags = {
    Name = "dwn-vpc"
  }
}

# Create 4 subnets in Avaialability Zones 2a and 2b
resource "aws_subnet" "dwn-subnet-2a-1" {
  vpc_id     = aws_vpc.dwn-vpc.id
  cidr_block = var.subnet_prefix[0]
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-subnet-1"
  }
}


resource "aws_subnet" "dwn-subnet-2a-2" {
  vpc_id     = aws_vpc.dwn-vpc.id
  cidr_block = var.subnet_prefix[1]
  availability_zone = "us-east-2a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "dwn-subnet-2b-1" {
  vpc_id     = aws_vpc.dwn-vpc.id
  cidr_block = var.subnet_prefix[2]
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-subnet-2"
  }
}

resource "aws_subnet" "dwn-subnet-2b-2" {
  vpc_id     = aws_vpc.dwn-vpc.id
  cidr_block = var.subnet_prefix[3]
  availability_zone = "us-east-2b"

  tags = {
    Name = "private-subnet-2"
  }
}

#Create internet gateway
resource "aws_internet_gateway" "dwn-gw" {
  vpc_id = aws_vpc.dwn-vpc.id

  tags = {
    Name = "dwn-IG"
  }
}

# Create route table
resource "aws_route_table" "dwn-rt" {
  vpc_id = aws_vpc.dwn-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dwn-gw.id
  }

  tags = {
    Name = "dwn-RT"
  }
}

# Assosiate public subnet to route table
resource "aws_route_table_association" "subnet-2a-1-rta" {
  subnet_id      = aws_subnet.dwn-subnet-2a-1.id
  route_table_id = aws_route_table.dwn-rt.id
}

resource "aws_route_table_association" "subnet-2b-1-rta" {
  subnet_id      = aws_subnet.dwn-subnet-2b-1.id
  route_table_id = aws_route_table.dwn-rt.id
}

# Security Groups 1
  # Allow ssh and http traffic to load balancer
resource "aws_security_group" "dwn-lb-ssh-http" {
  name        = "lb_ssh-http"
  description = "Allow ssh-http inbound traffic"
  vpc_id      = aws_vpc.dwn-vpc.id

# Inbound Rules
  #SSH access from anywhere
  ingress {
    description      = "ssh to LB"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

# Inbound Rules
  # HTTP access from anywhere
 ingress {
    description      = "http to LB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

# Outbound Rules
  # Internet access to anywhere
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_lb_ssh_http"
  }
}


# Security Groups 2
  # Allow ssh and http traffic from load balancer
  resource "aws_security_group" "dwn-instance-ssh-http" {
  name        = "instance-ssh-http"
  description = "Allow ssh-http inbound traffic"
  vpc_id      = aws_vpc.dwn-vpc.id

# Inbound Rules
  # SSH access from anywhere
  ingress {
    description      = "ssh from LB"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #security_groups  = [aws_security_group.dwn-lb-ssh-http.id]
  }

# Inbound Rules
  # HTTP access from anywhere
 ingress {
    description      = "http from LB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    #cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = [aws_security_group.dwn-lb-ssh-http.id]
  }

# Outbound Rules
  # Internet access to anywhere
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #security_groups  = [aws_security_group.dwn-lb-ssh-http.id]
  }

  tags = {
    Name = "allow-ec2_ssh_http"
  }
}


# Creating key pair
resource "aws_key_pair" "dwn-proj-key-pair" {
  key_name   = "dwn-proj-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyjN3LQmSmaJUWWP13wlLb4fpwQ/4Uo04LC79fPXedA8JUqPb1g9NknORTwwnTfit6zFrf9fjSJteN6EhJPl0N4EtIvSZWwpzg+LQ2f+t9/YLfOBPR+8vHXkf7+bcmwK8l5TLWf+Bihaft5hSvPzUNPNLtGDlkySFYSuqQT631KnQv/Scp03KrlD4JnS1VKgBIyIvXpdq2NG4D6HKUvAZYhSxxwL7MmDduWOOFTBdDm/Uuko4gB0Zft8GHjs5RslTjYVkM8dsD/hCWSwNMLpjdReB7X7o56lfP1yBeRXIuNNx/1CgMZcrC6rDLrwsrPWm/oBXTEA+IwZgysrA/pBAKgjqiqej3pVb37BW1bB6qHdV5kHwc+FUXsw8CqzDUYo8wgMq7ePYdSeUp/4rfP6MQXfDN5BSivZWblKahLVISXRb2FuUb9VbH265wQ7I7rlYtTyL43fRjYhnElBJEERF1EGeoNWFf8XlQEtVJjlEfnxKFk6NpriJGKssgaopkqrU= paulowie@Pauls-MacBook-Pro.local"
}


# Create load balancer
resource "aws_lb" "dwn-lb" {
  name               = "dwn-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dwn-lb-ssh-http.id]
  subnets            = [aws_subnet.dwn-subnet-2a-1.id, aws_subnet.dwn-subnet-2b-1.id]

  tags = {
    Environment = "Test"
  }
}

# Create launch template for EC2 instances
resource "aws_launch_template" "dwn-LT" {
  name = "dwn-LT"
  image_id = "ami-024e6efaf93d85776"
  instance_type = "t2.micro"
  key_name = aws_key_pair.dwn-proj-key-pair.id

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.dwn-instance-ssh-http.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "My-ASG-Instance"
    }
  }

  user_data = filebase64("userdata.sh")
}

# Create auto scaling group
resource "aws_autoscaling_group" "dwn-ASG" {
  vpc_zone_identifier = [aws_subnet.dwn-subnet-2a-1.id, aws_subnet.dwn-subnet-2b-1.id]
  
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2

  
  launch_template {
    id      = aws_launch_template.dwn-LT.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.dwn-TG.arn]
}

# Create target group
resource "aws_lb_target_group" "dwn-TG" {
  name     = "dwn-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.dwn-vpc.id
}

# create load balancer listener
resource "aws_lb_listener" "dwn-front_end" {
  load_balancer_arn = aws_lb.dwn-lb.arn
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dwn-TG.arn
  }
}