terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Configure the backend for state management if needed
# terraform {
#   backend "s3" {
#     bucket = "XXXXXXXXXXXXXXXXXXXXXXXXXXX"
#     key    = "state/terraform.tfstate"
#     region = "ap-southeast-2"
#   }
# }