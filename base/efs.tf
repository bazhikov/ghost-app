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

output "efs_dns_name" {
  value = aws_efs_file_system.ghost_content.dns_name
}
