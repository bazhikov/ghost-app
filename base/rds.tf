resource "aws_db_subnet_group" "ghost" {
  name        = "ghost-db-subnet-group"
  description = "Subnet group for Ghost RDS database"
  subnet_ids  = aws_subnet.subnet_db[*].id

  tags = {
    Name = "ghost-db-subnet-group"
  }
}

# data "aws_ssm_parameter" "db_password" {
#   name = "/ghost/dbpassw"
# }

resource "aws_db_instance" "ghost_db" {
    identifier              = "ghost-db"
    engine                  = "mysql"
    engine_version          = "8.0"
    instance_class          = "db.t3.micro"
    allocated_storage       = 20
    storage_type            = "gp2"
    db_subnet_group_name    = aws_db_subnet_group.ghost.name
    vpc_security_group_ids  = [aws_security_group.mysql.id]
    username                = var.db_username
    password                = aws_ssm_parameter.ghost_db_password.value
    skip_final_snapshot     = true
    publicly_accessible     = false
    multi_az = true
    deletion_protection = false
    
    tags = {
        Name = "ghost-db-instance"
    }
}

resource "aws_ssm_parameter" "ghost_db_password" {
    name        = "/ghost/dbpassw"
    description = "Ghost database password"
    type        = "SecureString"
    value       = random_password.db_password.result
    key_id = "alias/aws/ssm" # Use the default SSM KMS key for encryption

    tags = {
        Name = "ghost_db_password"
    }
}

resource "random_password" "db_password" {
    length  = 16
    special = true
    override_special = "_%@"
}

output "db_endpoint" {
    description = "The endpoint of the RDS database"
    value       = aws_db_instance.ghost_db.address
}