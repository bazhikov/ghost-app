variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnets with CIDR blocks and availability zones."
  type = list(object({
    cidr_block = string
    az         = string
  }))
  default = [
    {
      cidr_block = "10.10.1.0/24"
      az         = "a"
    },
    {
      cidr_block = "10.10.2.0/24"
      az         = "b"
    },
    {
      cidr_block = "10.10.3.0/24"
      az         = "c"
    }
  ]
}

# Below is the configuration for private subnets for the RDS database
variable "private_subnets" {
  description = "List of private subnets with CIDR blocks and availability zones."
  type = list(object({
    cidr_block = string
    az         = string
  }))
  default = [
    {
      cidr_block = "10.10.20.0/24"
      az         = "a"
    },
    {
      cidr_block = "10.10.21.0/24"
      az         = "b"
    },
    {
      cidr_block = "10.10.22.0/24"
      az         = "c"
    }
  ]
}

# ECS private subnets used for Fargate tasks
variable "ecs_private_subnets" {
  description = "List of ECS private subnets with CIDR blocks and availability zones."
  type = list(object({
    cidr_block = string
    az         = string
  }))
  default = [
    { cidr_block = "10.10.10.0/24", az = "a" },
    { cidr_block = "10.10.11.0/24", az = "b" },
    { cidr_block = "10.10.12.0/24", az = "c" }
  ]
}

variable "my_ip" {
  description = "Your public IP address with CIDR suffix"
  type        = string
  #   command to use: terraform apply -var="my_ip=$(curl -4 -s ifconfig.me)/32"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  default     = "ghost-ec2-pool"
}

variable "alb_name" {
  description = "The name to give the ALB (and the name the launch template will look up)."
  type        = string
  default     = "cloudx-alb"
}

variable "db_username" {
  description = "Username for the MySQL database."
  type        = string
  default     = "ghost_admin"
}