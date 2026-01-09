# admin-stack/projects.tf

# Web Application Project
module "web_app" {
  source = "../stack-factory"
  
  project_name     = "web-application"
  description      = "Main web application infrastructure"
  repository       = var.repository_name
  github_namespace = var.github_namespace
  project_root     = "projects/web-app"
  
  environments = ["development", "staging", "production"]
  
  space_ids = {
    development = spacelift_space.environment["development"].id
    staging     = spacelift_space.environment["staging"].id
    production  = spacelift_space.environment["production"].id
  }
  
  context_ids = [
    spacelift_context.aws_integration.id,
  ]
  
  environment_context_ids = {
    development = [spacelift_context.environment["development"].id]
    staging     = [spacelift_context.environment["staging"].id]
    production  = [spacelift_context.environment["production"].id]
  }
  
  labels = ["web", "application", "team-alpha"]
  
  enable_dependencies = true
  protect_production  = true
}

# Data Pipeline Project
module "data_pipeline" {
  source = "../stack-factory"
  
  project_name     = "data-pipeline"
  description      = "Data processing pipeline infrastructure"
  repository       = var.repository_name
  github_namespace = var.github_namespace
  project_root     = "projects/data-pipeline"
  
  environments = ["development", "production"]  # No staging for this project
  
  space_ids = {
    development = spacelift_space.environment["development"].id
    production  = spacelift_space.environment["production"].id
  }
  
  context_ids = [
    spacelift_context.aws_integration.id,
  ]
  
  environment_context_ids = {
    development = [spacelift_context.environment["development"].id]
    production  = [spacelift_context.environment["production"].id]
  }
  
  labels = ["data", "pipeline", "team-beta"]
  
  enable_dependencies = true
}

# Outputs
output "web_app_stacks" {
  description = "Web application stack IDs"
  value       = module.web_app.stack_ids
}

output "data_pipeline_stacks" {
  description = "Data pipeline stack IDs"
  value       = module.data_pipeline.stack_ids
}