variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "definitiv"
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
  default     = "definitiv.com.au"
}

variable "new_relic_license_key" {
  description = "New Relic license key for OTLP export"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
}

variable "tenants" {
  description = "List of tenant configurations"
  type = list(object({
    name           = string
    container_port = number
    cpu           = number
    memory        = number
    min_capacity  = number
    max_capacity  = number
    db_name       = string
  }))
  default = [
    {
      name           = "tenant1"
      container_port = 80
      cpu           = 1024
      memory        = 2048
      min_capacity  = 1
      max_capacity  = 5
      db_name       = "tenant1db"
    },
    {
      name           = "tenant2"
      container_port = 80
      cpu           = 2048
      memory        = 4096
      min_capacity  = 2
      max_capacity  = 10
      db_name       = "tenant2db"
    }
  ]
}