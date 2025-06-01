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


