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
          "elasticfilesystem:ClientWrite",
          "ssm:GetParameter*",
          "secretsmanager:GetSecretValue",
          "kms:Decrypt",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterEndpoints",
          "rds:DescribeDBClusterParameterGroups",
          "rds:DescribeDBClusterSnapshotAttributes",
          "rds:DescribeEvents",
          "rds:DescribeDBClusterSnapshots",
          "rds:DescribeDBClusterBacktracks",
          "rds:DescribeDBClusterBacktracks",
          "rds:Connect"
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

# Outputs
output "iam_policy_arn" {
  description = "The ARN of the IAM policy"
  value       = aws_iam_policy.ghost_app_policy.arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.ghost_app.arn
}

output "iam_instance_profile_arn" {
  description = "The ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.ghost_app_profile.arn
}