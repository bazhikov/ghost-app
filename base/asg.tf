resource "aws_autoscaling_group" "ghost_ec2_pool" {
    name = "ghost-ec2-pool"
    launch_template {
        id      = aws_launch_template.ghost.id
        version = "$Latest"
    }
    vpc_zone_identifier = aws_subnet.subnet_cloudx[*].id
    min_size            = 1
    max_size            = 3
    desired_capacity   = 1
    target_group_arns = [aws_lb_target_group.ghost_ec2_tg.arn]
    health_check_type  = "ELB"
    health_check_grace_period = 300
    tag {
        key                 = "Name"
        value               = "ghost-ec2-instance"
        propagate_at_launch = true
    }
}