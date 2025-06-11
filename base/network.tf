resource "aws_vpc" "cloudx" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "cloudx-vpc"
  }
}

resource "aws_subnet" "subnet_cloudx" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = var.public_subnets[count.index]["cidr_block"]
  availability_zone = "${var.aws_region}${var.public_subnets[count.index]["az"]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "cloudx-subnet-${var.public_subnets[count.index]["az"]}"
  }
}

resource "aws_internet_gateway" "cloudx-igw" {
  vpc_id = aws_vpc.cloudx.id
  tags = {
    Name = "cloudx-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cloudx.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudx-igw.id
  }
  tags = {
    Name = "cloudx-public-rt"
  }
}

resource "aws_route_table_association" "cloudx_public_assoc" {
  count          = length(aws_subnet.subnet_cloudx)
  subnet_id      = aws_subnet.subnet_cloudx[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Below is Private Subnet Configuration
resource "aws_subnet" "subnet_db" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = var.private_subnets[count.index]["cidr_block"]
  availability_zone = "${var.aws_region}${var.private_subnets[count.index]["az"]}"

  tags = {
    Name = "cloudx-private-subnet-${var.private_subnets[count.index]["az"]}"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.cloudx.id

  tags = {
    Name = "cloudx-private-rt"
  }
}
resource "aws_route_table_association" "cloudx_private_assoc" {
  count          = length(aws_subnet.subnet_db)
  subnet_id      = aws_subnet.subnet_db[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# ECS private subnets for Fargate tasks
resource "aws_subnet" "subnet_ecs" {
  count             = length(var.ecs_private_subnets)
  vpc_id            = aws_vpc.cloudx.id
  cidr_block        = var.ecs_private_subnets[count.index]["cidr_block"]
  availability_zone = "${var.aws_region}${var.ecs_private_subnets[count.index]["az"]}"

  tags = {
    Name = "ecs-private-${var.ecs_private_subnets[count.index]["az"]}"
  }
}

resource "aws_route_table_association" "ecs_private_assoc" {
  count          = length(aws_subnet.subnet_ecs)
  subnet_id      = aws_subnet.subnet_ecs[count.index].id
  route_table_id = aws_route_table.private_rt.id
}