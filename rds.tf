# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-${var.environment}-rds-sg"
  description = "Security group for RDS SQL Server instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-rds-sg"
    Environment = var.environment
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.app_name}-${var.environment}"
  subnet_ids  = aws_subnet.private[*].id
  description = "Subnet group for RDS SQL Server instances"

  tags = {
    Name        = "${var.app_name}-${var.environment}"
    Environment = var.environment
  }
}

# RDS Instance for each tenant
resource "aws_db_instance" "tenant" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  identifier           = "${var.app_name}-${var.environment}-${each.key}"
  engine              = "sqlserver-ex"
  engine_version      = "15.00.4316.3.v1"
  instance_class      = "db.t3.medium"
  allocated_storage   = 20
  storage_type        = "gp2"
  
  username            = "admin"
  password            = "temporarypassword123!" # Change this in production

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  skip_final_snapshot    = true
  multi_az              = false

  tags = {
    Name        = "${var.app_name}-${var.environment}-${each.key}"
    Environment = var.environment
    Tenant      = each.key
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs" {
  name        = "${var.app_name}-${var.environment}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-ecs-sg"
    Environment = var.environment
  }
}

# Security group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-alb-sg"
    Environment = var.environment
  }
}