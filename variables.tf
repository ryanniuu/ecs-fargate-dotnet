variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "dotnet-sample"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tenants" {
  description = "List of tenants and their configurations"
  type = list(object({
    name           = string
    domain        = string
    min_capacity  = number
    max_capacity  = number
    cpu          = number
    memory       = number
    db_name      = string
  }))
  default = [
    {
      name          = "tenant1"
      domain        = "tenant1.definitiv.com.au"
      min_capacity  = 1
      max_capacity  = 4
      cpu          = 1024
      memory       = 2048
      db_name      = "tenant1db"
    },
    {
      name          = "tenant2"
      domain        = "definitiv.com.au"
      min_capacity  = 1
      max_capacity  = 4
      cpu          = 1024
      memory       = 2048
      db_name      = "tenant2db"
    }
  ]
}