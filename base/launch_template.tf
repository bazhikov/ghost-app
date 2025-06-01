data "aws_lb" "cloudx_alb" {
  name = "cloudx-alb" # replace with your actual ALB name if different
}

resource "aws_launch_template" "ghost" {
  name_prefix   = "ghost-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ghost_app_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ec2_pool.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    LB_DNS_NAME = data.aws_lb.cloudx_alb.dns_name
  }))

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

