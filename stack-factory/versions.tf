# stack-factory/versions.tf
# Child modules must declare their own required_providers

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~> 1.0"
    }
  }
}
