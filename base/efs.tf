resource "aws_efs_file_system" "ghost_content" {
  creation_token = "ghost-content"
  tags = {
    Name = "ghost-content"
  }
}

resource "aws_efs_mount_target" "ghost_content_targets" {
  count           = length(aws_subnet.subnet_cloudx)
  file_system_id  = aws_efs_file_system.ghost_content.id
  subnet_id       = aws_subnet.subnet_cloudx[count.index].id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "ghost_ap" {
  file_system_id = aws_efs_file_system.ghost_content.id

  root_directory {
    path = "/ghost-content"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }
}

output "efs_dns_name" {
  value = aws_efs_file_system.ghost_content.dns_name
}
