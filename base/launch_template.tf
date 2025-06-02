# data "aws_lb" "cloudx_alb" {
#   name = var.alb_name
# }

resource "aws_launch_template" "ghost" {
  name_prefix   = "ghost-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ghost_app_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ec2_pool.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    LB_DNS_NAME = aws_lb.cloudx_alb.dns_name
  }))

    metadata_options {
        http_tokens               = "optional"
        http_put_response_hop_limit = 1
        http_endpoint             = "enabled"
    }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2023-ami-*-x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

