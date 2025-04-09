resource "aws_security_group" "rds" {
  name        = "${var.app_name}-${var.environment}-rds"
  description = "Allow inbound traffic from ECS tasks to RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-rds"
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.app_name}-${var.environment}"
  description = "RDS subnet group"
  subnet_ids  = module.vpc.private_subnets
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.app_name}-${var.environment}-sqlserver"
  family = "sqlserver-ee-15.0"

  parameter {
    name  = "max_connections"
    value = "1000"
  }
}

resource "random_password" "db_password" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }
  length   = 16
  special  = true
}

resource "aws_db_instance" "main" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  identifier = "${var.app_name}-${var.environment}-${each.key}"

  engine         = "sqlserver-ee"
  engine_version = "15.00.4236.7.v1"
  instance_class = "db.r6g.large"

  allocated_storage     = 20
  storage_type         = "gp3"
  storage_encrypted    = true
  
  db_name  = each.value.db_name
  username = "admin"
  password = random_password.db_password[each.key].result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  multi_az               = true
  skip_final_snapshot    = true

  tags = {
    Name        = "${var.app_name}-${var.environment}-${each.key}"
    Environment = var.environment
  }
}