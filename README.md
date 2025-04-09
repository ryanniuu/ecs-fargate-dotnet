# Multi-tenant AWS Infrastructure

This project implements a multi-tenant infrastructure on AWS using Terraform. The infrastructure is designed to host a containerized application with separate resources for different tenants.

## Architecture Overview

The infrastructure includes the following components:

- **VPC and Networking**:
  - Custom VPC with defined CIDR block
  - Multiple Availability Zones
  - Public and Private subnets
  - Internet Gateway and NAT Gateways
  - Route tables for public and private subnets

- **Container Infrastructure**:
  - ECS Cluster running on Fargate
  - Application Load Balancer with tenant-specific routing
  - ECR repository for container images
  - Fargate tasks with ARM64 architecture

- **Database**:
  - RDS instances for each tenant
  - Secure database access through security groups
  - MS SQL Server (Port 1433)

- **Security**:
  - Separate security groups for RDS, ECS tasks, and ALB
  - IAM roles and policies for ECS tasks
  - Network isolation between components

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (check `main.tf` for version requirements)
- Docker for container builds

## Configuration

### Variables

Key variables that need to be configured:

1. `aws_region`: AWS region for deployment
2. `environment`: Environment name (e.g., dev, staging, prod)
3. `tenants`: List of tenant configurations

### Tenant Configuration

Tenants are configured in `variables.tf`. Each tenant configuration includes:
- Name
- Database settings
- Custom configurations

## Deployment

1. Initialize Terraform:
```bash
terraform init
```

2. Review the plan:
```bash
terraform plan
```

3. Apply the infrastructure:
```bash
terraform validate
terraform apply
```

## Architecture Features

- **Multi-tenancy**: Separate resources and isolation for each tenant
- **High Availability**: Multi-AZ deployment with redundant components
- **Cost Optimization**: Uses Fargate Spot for cost-effective container hosting
- **Scalability**: Auto-scaling capabilities for ECS tasks
- **Security**: Network segmentation and security groups
- **Load Balancing**: Application Load Balancer with host-based routing

## Outputs

After deployment, you can access:
- ALB DNS name for application access
- Database endpoints for each tenant

## Maintenance

- Regular updates of container images
- Terraform state management
- Security group and network ACL updates as needed
- Monitoring and logging through CloudWatch

## Security Considerations

- All database access is restricted to application security group
- Public access is only through the ALB
- Private subnets for sensitive resources
- Least privilege IAM policies

## Resource Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

**Note**: Ensure you have backed up any important data before destroying the infrastructure.