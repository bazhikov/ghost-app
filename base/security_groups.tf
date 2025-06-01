resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "allows access to bastion"
  vpc_id      = aws_vpc.cloudx.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
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
    security_groups = [aws_security_group.bastion.id]
  }
  ingress {
    description = "EFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  # ingress {
  #     description = "App port from ALB"
  #     from_port   = 2368
  #     to_port     = 2368
  #     protocol    = "tcp"
  #     security_groups = [aws_security_group.alb.id]
  # }
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

resource "aws_security_group" "alb" {
  name        = "alb"
  description = "allows access to ALB"
  vpc_id      = aws_vpc.cloudx.id

  ingress {
    description = "HTTP from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  # egress {
  #     description = "Allow all outbound"
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     cidr_blocks = [aws_security_group.ec2_pool.id]
  # }
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