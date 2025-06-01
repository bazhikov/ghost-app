resource "aws_iam_role" "ghost_app" {
  name = "ghost_app_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ghost_app_policy" {
  name        = "ghost_app_policy"
  description = "Allow EC2 and EFS permissions for Ghost app"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ghost_app_attach" {
  role       = aws_iam_role.ghost_app.name
  policy_arn = aws_iam_policy.ghost_app_policy.arn
}

resource "aws_iam_instance_profile" "ghost_app_profile" {
  name = "ghost_app_instance_profile"
  role = aws_iam_role.ghost_app.name
}