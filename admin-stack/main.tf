# Add to main.tf - This creates the admin stack itself

# Admin stack that manages all Spacelift resources
resource "spacelift_stack" "admin" {
  name        = "admin-stack"
  description = "Self-managing Spacelift admin stack"
  space_id    = spacelift_space.platform.id
  labels      = ["admin", "platform", "critical"]

  repository = var.repository_name
  branch     = "main"

  project_root = "admin-stack"

  # Enable administrative access
  administrative = true

  # Protect from accidental deletion
  protect_from_deletion = true

  # Auto-deploy on merge to main
  autodeploy = false # Start with manual deploys for safety

  # OpenTofu configuration
  terraform_version = "1.6.0"

  github_enterprise {
    namespace = var.github_namespace
  }
}

# Attach AWS context to admin stack
resource "spacelift_context_attachment" "admin_aws" {
  stack_id   = spacelift_stack.admin.id
  context_id = spacelift_context.aws_integration.id
}

# Output admin stack ID
output "admin_stack_id" {
  description = "Admin stack ID"
  value       = spacelift_stack.admin.id
}
