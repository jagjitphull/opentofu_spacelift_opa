# admin-stack/main.tf
# Self-managing administrative stack

resource "spacelift_stack" "admin" {
  name         = "admin-stack"
  description  = "Self-managing administrative stack for Spacelift configuration"
  repository   = var.repository_name  # Just repo name, not org/repo
  branch       = var.branch
  project_root = "admin-stack"
  space_id     = spacelift_space.platform.id

  # Use OpenTofu instead of Terraform
  terraform_workflow_tool = "OPEN_TOFU"
  terraform_version       = "1.8.0"

  # GitHub integration
  github_enterprise {
    namespace = var.github_namespace
  }

  autodeploy = true

  labels = ["admin", "platform", "self-managing"]
}

# Role attachment replaces deprecated 'administrative = true'
resource "spacelift_role_attachment" "admin_stack" {
  role_id  = "ADMIN"
  stack_id = spacelift_stack.admin.id
  space_id = spacelift_space.platform.id
}

