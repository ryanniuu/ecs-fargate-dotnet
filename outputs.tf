output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "rds_endpoints" {
  description = "Endpoints of the RDS instances"
  value = {
    for tenant, instance in aws_db_instance.main : tenant => instance.endpoint
  }
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_urls" {
  description = "URLs for accessing the services"
  value = {
    for tenant in var.tenants : tenant.name => "https://${tenant.name}.${var.domain_name}"
  }
}