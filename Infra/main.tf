provider "aws" {
  region = var.region
}

# VPC creation
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.azs[1]
  map_public_ip_on_launch = false
  tags = {
    Name = "Private Subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# NAT Gateway (Public Subnet)
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "main-nat-gateway"
  }
}

# Route Tables for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Route Tables for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Group
resource "aws_security_group" "ecs" {
  name        = var.security_group_name
  description = "Allow inbound traffic to ECS tasks"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
}

# ECS Task Definition for Service 1 (Patient service)
resource "aws_ecs_task_definition" "patient_service" {
  family                   = "patient_service-task"
  execution_role_arn       = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_EXECUTION_ROLE"
  task_role_arn            = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_TASK_ROLE"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions    = jsonencode([{
    name      = "patient_service-container"
    image     = "your-dockerhub-username/patient_service-image"  # Replace with Node.js image
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 3000  # Adjust the port number for your Node.js service
        hostPort      = 3000
      }
    ]
  }])
}

# ECS Task Definition for Service 2 (Appointment Service)
resource "aws_ecs_task_definition" "appointment_service" {
  family                   = "appointment_service-task"
  execution_role_arn       = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_EXECUTION_ROLE"
  task_role_arn            = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_TASK_ROLE"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions    = jsonencode([{
    name      = "appointment_service-container"
    image     = "your-dockerhub-username/appointment_service-image"  # Replace with Node.js image
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 4000  # Adjust the port number for second Node.js service
        hostPort      = 4000
      }
    ]
  }])
}

# ECS Service for Patient Service ()
resource "aws_ecs_service" "patient_service" {
  name            = "patient_service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service_1.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.private.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
}

# ECS Service for appointment_service
resource "aws_ecs_service" "appointment_service" {
  name            = "appointment_service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service_2.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.private.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
}
