# contexts.tf

# AWS integration context
resource "spacelift_context" "aws_integration" {
  name        = "aws-integration"
  description = "AWS credentials and configuration"
  space_id    = spacelift_space.platform.id
  labels      = ["aws", "credentials", "shared"]
}

# Add AWS region configuration
resource "spacelift_environment_variable" "aws_region" {
  context_id = spacelift_context.aws_integration.id
  name       = "AWS_DEFAULT_REGION"
  value      = "us-west-2"
  write_only = false
}

# Environment-specific contexts
resource "spacelift_context" "environment" {
  for_each = toset(var.environments)

  name        = "${each.key}-config"
  description = "Configuration for ${each.key} environment"
  space_id    = spacelift_space.environment[each.key].id
  labels      = [each.key, "config", "environment"]
}

# Environment name variable in each context
resource "spacelift_environment_variable" "env_name" {
  for_each = toset(var.environments)

  context_id = spacelift_context.environment[each.key].id
  name       = "TF_VAR_environment"
  value      = each.key
  write_only = false
}

# Environment-specific settings
resource "spacelift_environment_variable" "env_settings" {
  for_each = {
    "development" = { log_level = "DEBUG", replicas = "1" }
    "staging"     = { log_level = "INFO", replicas = "2" }
    "production"  = { log_level = "WARN", replicas = "3" }
  }

  context_id = spacelift_context.environment[each.key].id
  name       = "TF_VAR_default_replicas"
  value      = each.value.replicas
  write_only = false
}

# Shared secrets context (write-only values)
resource "spacelift_context" "secrets" {
  name        = "shared-secrets"
  description = "Shared secrets for all stacks"
  space_id    = spacelift_space.platform.id
  labels      = ["secrets", "sensitive"]
}

# Output context IDs
output "context_ids" {
  description = "Map of context names to IDs"
  value = merge(
    { "aws-integration" = spacelift_context.aws_integration.id },
    { for k, v in spacelift_context.environment : k => v.id },
    { "secrets" = spacelift_context.secrets.id }
  )
}


