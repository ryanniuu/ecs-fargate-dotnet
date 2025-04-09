output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "The DNS name of the load balancer"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "The URL of the ECR repository"
}

output "rds_endpoints" {
  value = {
    for tenant, instance in aws_db_instance.tenant : tenant => instance.endpoint
  }
  description = "The endpoints of the RDS instances"
  sensitive   = true
}