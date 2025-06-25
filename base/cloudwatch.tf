resource "aws_cloudwatch_dashboard" "ghost_dashboard" {
  dashboard_name = "GhostInfraDashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "ghost-ec2-pool" ]
          ],
          "period" : 300,
          "stat" : "Average",
          "region" : var.aws_region,
          "title" : "EC2 Avg CPU (ASG)"
        }
      },
      {
        "type" : "metric",
        "x" : 12,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [ "AWS/ECS", "CPUUtilization", "ClusterName", "ghost-cluster", "ServiceName", "ghost-service" ],
            [ ".", "RunningTaskCount", ".", ".", ".", "." ]
          ],
          "period" : 300,
          "stat" : "Average",
          "region" : var.aws_region,
          "title" : "ECS Service CPU & Running Tasks"
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 6,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [ "AWS/EFS", "ClientConnections", "FileSystemId", aws_efs_file_system.ghost_content.id ],
            [ ".", "StorageBytes", ".", "." ]
          ],
          "period" : 300,
          "stat" : "Average",
          "region" : var.aws_region,
          "title" : "EFS Connections & Storage (MB)"
        }
      },
      {
        "type" : "metric",
        "x" : 12,
        "y" : 6,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.ghost_db.id ],
            [ ".", "CPUUtilization", ".", "." ],
            [ ".", "ReadIOPS", ".", "." ],
            [ ".", "WriteIOPS", ".", "." ]
          ],
          "period" : 300,
          "stat" : "Average",
          "region" : var.aws_region,
          "title" : "RDS: Connections, CPU, IOPS"
        }
      }
    ]
  })
}
