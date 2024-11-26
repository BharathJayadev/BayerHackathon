#this file stores the default values
variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  description = "Private Subnet CIDR block"
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR block"
  default     = "10.0.0.0/24"
}

variable "azs" {
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  default     = "my-ecs-cluster"
}

variable "security_group_name" {
  description = "Security Group Name"
  default     = "ecs-sg"
}
