# stack-factory/main.tf
# Fixed: Use static keys for for_each to avoid "unknown value" errors

# ------------------------------------------------------------------------------
# STACK CREATION
# ------------------------------------------------------------------------------
resource "spacelift_stack" "project" {
  for_each = toset(var.environments)

  name         = "${var.project_name}-${each.value}"
  description  = var.description != "" ? "${var.description} (${each.value})" : "${var.project_name} stack for ${each.value} environment"
  repository   = var.repository  # Just the repo name, not org/repo
  branch       = var.branch
  project_root = var.project_root != "" ? var.project_root : var.project_name
  space_id     = var.space_ids[each.value]
  
  # Disable auto-deploy for production if protection enabled
  autodeploy   = var.protect_production && each.value == "production" ? false : var.autodeploy

  labels = concat(
    var.labels,
    [var.project_name, each.value],
    var.protect_production && each.value == "production" ? ["protected"] : []
  )

  # Use OpenTofu instead of Terraform
  terraform_workflow_tool = "OPEN_TOFU"
  terraform_version       = var.opentofu_version != "" ? var.opentofu_version : "1.8.0"

  # GitHub integration - specify namespace for GitHub App
  dynamic "github_enterprise" {
    for_each = var.github_namespace != "" ? [1] : []
    content {
      namespace = var.github_namespace
    }
  }
}

# ------------------------------------------------------------------------------
# STACK DEPENDENCIES (for promotion chains)
# ------------------------------------------------------------------------------
resource "spacelift_stack_dependency" "promotion" {
  for_each = var.enable_dependencies ? {
    for idx, env in var.environments : env => var.environments[idx - 1]
    if idx > 0
  } : {}

  stack_id            = spacelift_stack.project[each.key].id
  depends_on_stack_id = spacelift_stack.project[each.value].id
}

# ------------------------------------------------------------------------------
# SHARED CONTEXT ATTACHMENTS
# Fixed: Build keys from static values (environment + context_id index)
# ------------------------------------------------------------------------------
locals {
  # Create a static map for shared context attachments
  # Keys are built from known values: environment name + context index
  shared_context_attachments = merge([
    for env in var.environments : {
      for idx, ctx_id in var.context_ids : "${env}-ctx-${idx}" => {
        environment = env
        context_id  = ctx_id
      }
    }
  ]...)

  # Create a static map for environment-specific context attachments
  env_context_attachments = merge([
    for env in var.environments : {
      for idx, ctx_id in lookup(var.environment_context_ids, env, []) : "${env}-envctx-${idx}" => {
        environment = env
        context_id  = ctx_id
      }
    }
  ]...)
}

resource "spacelift_context_attachment" "shared" {
  for_each = local.shared_context_attachments

  # Stack ID is looked up using the static environment key
  stack_id   = spacelift_stack.project[each.value.environment].id
  context_id = each.value.context_id
}

# ------------------------------------------------------------------------------
# ENVIRONMENT-SPECIFIC CONTEXT ATTACHMENTS
# ------------------------------------------------------------------------------
resource "spacelift_context_attachment" "environment" {
  for_each = local.env_context_attachments

  stack_id   = spacelift_stack.project[each.value.environment].id
  context_id = each.value.context_id
}

# ------------------------------------------------------------------------------
# ROLE ATTACHMENT (replaces deprecated administrative = true)
# ------------------------------------------------------------------------------
resource "spacelift_role_attachment" "admin" {
  for_each = var.administrative ? toset(var.environments) : toset([])

  role_id  = "ADMIN"
  stack_id = spacelift_stack.project[each.key].id
  space_id = var.space_ids[each.key]
}

