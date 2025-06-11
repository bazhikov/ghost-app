# data "aws_lb" "cloudx_alb" {
#   name = var.alb_name
# }

resource "aws_launch_template" "ghost" {
  name_prefix   = "ghost-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  key_name      = var.key_name

  block_device_mappings {
    device_name = "/dev/xvda" # or whatever your AMI’s root device is
    ebs {
      volume_size           = 20    # size in GB
      volume_type           = "gp3" # gp3 (or gp2) is fine
      delete_on_termination = true  # auto‐cleanup
    }
  }

  #   network_interfaces {
  #     associate_public_ip_address = true
  #   }

  iam_instance_profile {
    name = aws_iam_instance_profile.ghost_app_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ec2_pool.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    LB_DNS_NAME = aws_lb.cloudx_alb.dns_name,
    REGION      = var.aws_region,
    EFS_ID      = aws_efs_file_system.ghost_content.id
    DB_URL      = aws_db_instance.ghost_db.address,
    DB_USER     = var.db_username,
    DB_NAME     = "ghostdb",
  }))

  metadata_options {
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
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
    values = ["al2023-ami-*-x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

