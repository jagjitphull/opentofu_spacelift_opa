# projects/web-app/development/main.tf
# Simple development environment infrastructure

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "web-application"
      ManagedBy   = "OpenTofu"
    }
  }
}

variable "environment" {
  type    = string
  default = "development"
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

# Simple S3 bucket for the environment
resource "aws_s3_bucket" "app_assets" {
  bucket = "web-app-assets-${var.environment}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

output "bucket_name" {
  value = aws_s3_bucket.app_assets.id
}

output "bucket_arn" {
  value = aws_s3_bucket.app_assets.arn
}
