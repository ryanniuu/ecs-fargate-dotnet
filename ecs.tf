resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name    = aws_cloudwatch_log_group.ecs_cluster.name
      }
    }
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-cluster"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name              = "/aws/ecs/${var.app_name}-${var.environment}-cluster"
  retention_in_days = 14

  tags = {
    Name        = "${var.app_name}-${var.environment}-cluster-logs"
    Environment = var.environment
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

# Task execution role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.app_name}-${var.environment}-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role for application permissions
resource "aws_iam_role" "ecs_task" {
  name = "${var.app_name}-${var.environment}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Create task definition and service for each tenant
resource "aws_ecs_task_definition" "app" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  family                   = "${var.app_name}-${var.environment}-${each.value.name}"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = each.value.cpu
  memory                  = each.value.memory
  execution_role_arn      = aws_iam_role.ecs_task_execution.arn
  task_role_arn          = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture       = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name  = each.value.name
      image = "mcr.microsoft.com/dotnet/samples:latest"
      
      portMappings = [
        {
          containerPort = each.value.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DATABASE_CONNECTION"
          value = "Server=${aws_db_instance.main[each.key].endpoint};Database=${each.value.db_name};User Id=${aws_db_instance.main[each.key].username};Password=${aws_db_instance.main[each.key].password}"
        },
        {
          name  = "OTEL_RESOURCE_ATTRIBUTES"
          value = "service.name=${each.value.name}"
        },
        {
          name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
          value = "http://localhost:4317"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = aws_cloudwatch_log_group.app[each.key].name
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name  = "aws-otel-collector"
      image = "amazon/aws-otel-collector:latest"
      
      command = [
        "--config=/etc/ecs/otel-collector-config.yaml"
      ]

      environment = [
        {
          name  = "NEW_RELIC_LICENSE_KEY"
          value = var.new_relic_license_key
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = aws_cloudwatch_log_group.app[each.key].name
          awslogs-stream-prefix = "ecs-otel"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "app" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  name              = "/aws/ecs/${var.app_name}-${var.environment}-${each.key}"
  retention_in_days = 14

  tags = {
    Name        = "${var.app_name}-${var.environment}-${each.key}-logs"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "app" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  name            = "${var.app_name}-${var.environment}-${each.value.name}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app[each.key].arn
  desired_count   = each.value.min_capacity
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app[each.key].arn
    container_name   = each.value.name
    container_port   = each.value.container_port
  }

  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  enable_execute_command = true

  tags = {
    Name        = "${var.app_name}-${var.environment}-${each.value.name}"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-${var.environment}-ecs-tasks"
  description = "Allow inbound traffic from ALB to ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
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
    Name        = "${var.app_name}-${var.environment}-ecs-tasks"
    Environment = var.environment
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "app" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  max_capacity       = each.value.max_capacity
  min_capacity       = each.value.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  name               = "${var.app_name}-${var.environment}-${each.value.name}-cpu"
  policy_type       = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.app[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "memory" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  name               = "${var.app_name}-${var.environment}-${each.value.name}-memory"
  policy_type       = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.app[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}