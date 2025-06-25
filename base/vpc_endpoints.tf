# Interface VPC endpoints accessed by Fargate tasks
locals {
    # Ensure unique AZs for each endpoint (must be in different AZs)
    ssm_endpoint_subnets_ecs = [
      aws_subnet.subnet_ecs[0].id,   # e.g., eu-central-1a
      aws_subnet.subnet_ecs[1].id    # e.g., eu-central-1b
  ]

    ssm_endpoint_subnets_ec2 = [
      aws_subnet.subnet_cloudx[2].id # e.g., eu-central-1c
  ]

}

# ECS: Private subnets (ECS tasks)
resource "aws_vpc_endpoint" "ssm_ecs" {
  vpc_id              = aws_vpc.cloudx.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.ssm_endpoint_subnets_ecs
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "ssm-endpoint-for-ecs"
  }
}

# EC2: Public subnet (EC2 pool)
resource "aws_vpc_endpoint" "ssm_ec2" {
  vpc_id              = aws_vpc.cloudx.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.ssm_endpoint_subnets_ec2
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = false # IMPORTANT: don't override public DNS for EC2

  tags = {
    Name = "ssm-endpoint-for-ec2"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.cloudx.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.subnet_ecs[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.cloudx.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.subnet_ecs[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "efs" {
  vpc_id              = aws_vpc.cloudx.id
  service_name        = "com.amazonaws.${var.aws_region}.elasticfilesystem"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.subnet_ecs[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.cloudx.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.subnet_ecs[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = aws_vpc.cloudx.id
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.subnet_ecs[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

# Gateway endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.cloudx.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]
}

output "efs_vpc_endpoint_id" {
  description = "ID of the VPC interface endpoint used for EFS"
  value       = aws_vpc_endpoint.efs.id
}