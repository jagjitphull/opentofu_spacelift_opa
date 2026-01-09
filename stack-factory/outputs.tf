# stack-factory/outputs.tf

output "stack_ids" {
  description = "Map of environment name to stack ID"
  value       = { for env, stack in spacelift_stack.project : env => stack.id }
}

output "stack_names" {
  description = "Map of environment name to stack name"
  value       = { for env, stack in spacelift_stack.project : env => stack.name }
}

output "stacks" {
  description = "Full stack objects for reference"
  value       = spacelift_stack.project
}
