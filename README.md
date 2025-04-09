# Multi-tenant .NET Application Infrastructure

This repository contains Terraform configurations to deploy a multi-tenant .NET application on AWS with the following features:

- AWS ECS Fargate with Graviton (ARM64) processors and Fargate Spot for cost optimization
- Multi-tenant architecture with separate databases per tenant
- Application Load Balancer with subdomain-based routing
- AWS RDS SQL Server Enterprise Edition
- AWS Distro for OpenTelemetry (ADOT) integration with New Relic
- Secure networking with public and private subnets

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform v1.0 or later
3. SSL certificate in AWS Certificate Manager for your domain
4. New Relic account and license key

## Infrastructure Components

### Networking
- VPC with public and private subnets across 3 availability zones
- Internet Gateway for public subnets
- NAT Gateway for private subnets
- Security groups for ALB, ECS tasks, and RDS

### Compute
- ECS Cluster using Fargate and Fargate Spot
- Task definitions with Graviton2 (ARM64) support
- Auto-scaling based on CPU and Memory utilization
- ADOT Collector sidecar for observability

### Database
- RDS SQL Server Enterprise Edition instances (one per tenant)
- Multi-AZ deployment for high availability
- Automated backups and maintenance windows

### Load Balancing
- Application Load Balancer with HTTP to HTTPS redirect
- Host-based routing for tenant isolation
- Health checks and target groups

## Deployment

1. Set up required variables:
   ```bash
   export TF_VAR_new_relic_license_key="your-license-key"
   export TF_VAR_certificate_arn="your-certificate-arn"
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Tenant Management

The infrastructure supports multiple tenants through the `tenants` variable in `variables.tf`. Each tenant configuration includes:

- Container resources (CPU/Memory)
- Auto-scaling settings
- Database name
- Container port

To add a new tenant, extend the `tenants` list in `variables.tf`.

## Observability

The application uses AWS Distro for OpenTelemetry to collect:
- Traces
- Metrics
- Logs

Data is exported to New Relic through the OTLP endpoint.

## Security Considerations

- All sensitive traffic flows through private subnets
- RDS instances are only accessible from ECS tasks
- HTTPS is enforced with automatic HTTP to HTTPS redirection
- Database passwords are automatically generated and managed by Terraform
- All data at rest is encrypted

## Cost Optimization

- Uses Fargate Spot for reduced compute costs
- Auto-scaling based on actual usage
- Graviton2 processors for better price-performance
- Multi-AZ RDS for production workloads

## Outputs

After deployment, you can view:
- ALB DNS name
- RDS endpoints
- ECS cluster name
- Service URLs for each tenant

## Notes

- The ALB DNS name should be configured in your DNS provider (e.g., Route 53)
- Database credentials should be securely passed to applications
- Monitor New Relic dashboards for application performance
- Regular backup verification is recommended