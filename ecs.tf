# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}"
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 1024
  memory                  = 2048
  execution_role_arn      = aws_iam_role.ecs_execution.arn
  task_role_arn          = aws_iam_role.ecs_task.arn
  runtime_platform {
    cpu_architecture = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name  = var.app_name
      image = "${aws_ecr_repository.app.repository_url}:latest"
      portMappings = [
        {
          containerPort = 8080
          hostPort     = 8080
          protocol     = "tcp"
        }
      ]
      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = var.environment
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.app_name}-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.app_name}-${var.environment}"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.app_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.app_name}-${var.environment}"
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.app_name}-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = aws_subnet.public[*].id

  tags = {
    Name        = "${var.app_name}-${var.environment}"
    Environment = var.environment
  }
}

# ALB Target Groups and ECS Services for each tenant

resource "aws_lb_target_group" "tenant" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  name        = "${var.app_name}-${var.environment}-${each.key}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-${each.key}"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant["tenant2"].arn
  }
}

resource "aws_lb_listener_rule" "tenant" {
  for_each = { for tenant in var.tenants : tenant.name => tenant if tenant.name != "tenant2" }

  listener_arn = aws_lb_listener.http.arn
  priority     = 100 + index(var.tenants[*].name, each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant[each.key].arn
  }

  condition {
    host_header {
      values = [each.value.domain]
    }
  }
}

# ECS Service for each tenant
resource "aws_ecs_service" "tenant" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  name            = "${var.app_name}-${var.environment}-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = each.value.min_capacity
  platform_version = "1.4.0"

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight           = 100
    base            = each.value.min_capacity
  }

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tenant[each.key].arn
    container_name   = var.app_name
    container_port   = 8080
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-${each.key}"
    Environment = var.environment
    Tenant      = each.key
  }
}

# Auto Scaling for each tenant
resource "aws_appautoscaling_target" "ecs" {
  for_each = { for tenant in var.tenants : tenant.name => tenant }

  max_capacity       = each.value.max_capacity
  min_capacity       = each.value.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.tenant[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}