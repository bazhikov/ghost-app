resource "aws_lb" "cloudx_alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.subnet_cloudx[*].id

  enable_deletion_protection = false

  tags = {
    Name = var.alb_name
  }
}

resource "aws_lb_target_group" "ghost_ec2_tg" {
  name     = "ghost-ec2"
  port     = 2368
  protocol = "HTTP"
  vpc_id   = aws_vpc.cloudx.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = {
    Name = "ghost-ec2-tg"
  }
}

resource "aws_lb_target_group" "ghost_fargate_tg" {
  name        = "ghost-fargate"
  port        = 2368
  protocol    = "HTTP"
  vpc_id      = aws_vpc.cloudx.id
  target_type = "ip"

  health_check {
    path                = "/ghost"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200,301,302"
  }

  tags = {
    Name = "ghost-fargate-tg"
  }
}

resource "aws_lb_listener" "ghost_listener" {
  load_balancer_arn = aws_lb.cloudx_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.ghost_ec2_tg.arn
        weight = 50
      }
      target_group {
        arn    = aws_lb_target_group.ghost_fargate_tg.arn
        weight = 50
      }
      stickiness {
        enabled  = false
        duration = 300
      }
    }
  }
  tags = {
    Name = "cloudx-alb-http-listener"
  }
}