# spaces.tf

# Root-level spaces for organizational structure
resource "spacelift_space" "environment" {
  for_each = toset(var.environments)

  name             = title(each.key)
  description      = "${title(each.key)} environment resources"
  parent_space_id  = "root"
  labels           = [each.key, "environment"]
  inherit_entities = true
}

# Platform space for admin resources
resource "spacelift_space" "platform" {
  name             = "Platform"
  description      = "Platform team and shared resources"
  parent_space_id  = "root"
  labels           = ["platform", "admin"]
  inherit_entities = true
}

# Team spaces under development environment
resource "spacelift_space" "team" {
  for_each = var.teams

  name             = each.value.name
  description      = each.value.description
  parent_space_id  = spacelift_space.environment["development"].id
  labels           = [each.key, "team"]
  inherit_entities = true
}

# Output space IDs for reference
output "space_ids" {
  description = "Map of space names to IDs"
  value = merge(
    { for k, v in spacelift_space.environment : k => v.id },
    { "platform" = spacelift_space.platform.id },
    { for k, v in spacelift_space.team : "team-${k}" => v.id }
  )
}
