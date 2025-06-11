resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "allows access to bastion"
  vpc_id      = aws_vpc.cloudx.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    description      = "Allow ICMP Echo (ping)"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = [var.my_ip]
    ipv6_cidr_blocks = []
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "ec2_pool" {
  name        = "ec2-pool"
  description = "allows access to ec2 instances"
  vpc_id      = aws_vpc.cloudx.id

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  ingress {
    description = "EFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ec2-pool-sg"
  }
}

# Security group for ECS Fargate tasks
resource "aws_security_group" "fargate_pool" {
  name        = "fargate_pool"
  description = "Allows access for Fargate instances"
  vpc_id      = aws_vpc.cloudx.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fargate-pool-sg"
  }
}

resource "aws_security_group_rule" "fargate_pool_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 2368
  to_port                  = 2368
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fargate_pool.id
  source_security_group_id = aws_security_group.alb.id
}

# Allow NFS traffic from the EFS security group to Fargate tasks
resource "aws_security_group_rule" "fargate_from_efs" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fargate_pool.id
  source_security_group_id = aws_security_group.efs.id
  description              = "Allow NFS from EFS"
}

# Security group used by VPC interface endpoints
resource "aws_security_group" "vpc_endpoint" {
  name        = "vpc-endpoint"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.cloudx.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-endpoint-sg"
  }
}

resource "aws_security_group_rule" "vpc_endpoint_ingress_from_fargate" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoint.id
  source_security_group_id = aws_security_group.fargate_pool.id
}

resource "aws_security_group" "alb" {
  name        = "alb"
  description = "allows access to ALB"
  vpc_id      = aws_vpc.cloudx.id

  ingress {
    description = "HTTP from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // [var.my_ip]
  }
  tags = {
    Name = "alb-sg"
  }
}

resource "aws_security_group_rule" "alb_to_ec2" {
  type                     = "ingress"
  from_port                = 2368
  to_port                  = 2368
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_pool.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow ALB to EC2 instances on port 2368"
}

resource "aws_security_group_rule" "ec2_to_alb" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.ec2_pool.id
  description              = "Allow EC2 instances to ALB"
}

resource "aws_security_group_rule" "icmp_from_bastion" {
  type                     = "ingress"
  from_port                = -1 # ICMP “all types”
  to_port                  = -1
  protocol                 = "icmp"
  security_group_id        = aws_security_group.ec2_pool.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "Allow ICMP (ping) from Bastion"
}

resource "aws_security_group" "efs" {
  name        = "efs"
  description = "defines access to efs mount points"
  vpc_id      = aws_vpc.cloudx.id

  ingress {
    description     = "EFS from VPC"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_pool.id]
  }
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = {
    Name = "efs-sg"
  }
}

# For RDS MySQL Database Security Group
resource "aws_security_group" "mysql" {
  name        = "mysql-sg"
  description = "Defines access to MySQL Database"
  vpc_id      = aws_vpc.cloudx.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "mysql-sg"
  }
}

resource "aws_security_group_rule" "mysql_ingress_ec2_pool" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mysql.id
  source_security_group_id = aws_security_group.ec2_pool.id
  description              = "Allow MySQL access from EC2 pool"
}

# Outputs
output "bastion_sg_id" {
  description = "The ID of the Bastion Security Group"
  value       = aws_security_group.bastion_sg.id
}

output "ec2_pool_sg_id" {
  description = "The ID of the EC2 Pool Security Group"
  value       = aws_security_group.ec2_pool.id
}

output "alb_sg_id" {
  description = "The ID of the ALB Security Group"
  value       = aws_security_group.alb.id
}

output "efs_sg_id" {
  description = "The ID of the EFS Security Group"
  value       = aws_security_group.efs.id
}

output "mysql_sg_id" {
  description = "The ID of the MySQL Security Group"
  value       = aws_security_group.mysql.id
}
