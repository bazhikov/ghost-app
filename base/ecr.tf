resource "aws_ecr_repository" "ghost" {
  name                 = "ghost"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

output "ecr_repo_url" {
  value = aws_ecr_repository.ghost.repository_url
}