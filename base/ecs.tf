resource "aws_ecs_cluster" "ghost" {
  name = "ghost"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

locals {
  ghost_container_def = jsonencode([
    {
      name      = "ghost_container"
      image     = "${aws_ecr_repository.ghost.repository_url}:5.121"
      essential = true
      environment = [
        { name = "database__client", value = "mysql" },
        { name = "database__connection__host", value = aws_db_instance.ghost_db.address },
        { name = "database__connection__user", value = var.db_username },
        { name = "database__connection__password", value = aws_ssm_parameter.ghost_db_password.value },
        { name = "database__connection__database", value = "ghostdb" }
      ]
      mountPoints = [{
        containerPath = "/var/lib/ghost/content"
        sourceVolume  = "ghost_volume"
      }]
      portMappings = [{
        containerPort = 2368
        hostPort      = 2368
      }]
    }
  ])
}

resource "aws_ecs_task_definition" "ghost" {
  family                   = "task_def_ghost"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ghost_ecs.arn
  task_role_arn            = aws_iam_role.ghost_ecs.arn
  container_definitions    = local.ghost_container_def

  volume {
    name = "ghost_volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.ghost_content.id
    }
  }
}

resource "aws_ecs_service" "ghost" {
  name            = "ghost"
  cluster         = aws_ecs_cluster.ghost.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.ghost.arn
  desired_count   = 1

  network_configuration {
    subnets          = aws_subnet.subnet_ecs[*].id
    security_groups  = [aws_security_group.fargate_pool.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ghost_fargate_tg.arn
    container_name   = "ghost_container"
    container_port   = 2368
  }

  depends_on = [
    aws_lb_listener.ghost_listener,
    aws_efs_mount_target.ghost_content_targets
  ]  
}
