# stack-factory/variables.tf

variable "project_name" {
  description = "Name of the project (used in stack names)"
  type        = string
}

variable "description" {
  description = "Description for the project stacks"
  type        = string
  default     = ""
}

variable "github_namespace" {
  description = "GitHub organization or user namespace"
  type        = string
  default     = ""
}

variable "environments" {
  description = "List of environments to create stacks for"
  type        = list(string)
  default     = ["development", "staging", "production"]
}

variable "repository" {
  description = "GitHub repository name"
  type        = string
}

variable "branch" {
  description = "Git branch to track"
  type        = string
  default     = "main"
}

variable "project_root" {
  description = "Path to the project root in the repository (defaults to project_name)"
  type        = string
  default     = ""
}

variable "space_ids" {
  description = "Map of environment name to Spacelift space ID"
  type        = map(string)
}

variable "labels" {
  description = "Additional labels to apply to all stacks"
  type        = list(string)
  default     = []
}

variable "context_ids" {
  description = "List of shared context IDs to attach to all stacks"
  type        = list(string)
  default     = []
}

variable "environment_context_ids" {
  description = "Map of environment name to list of environment-specific context IDs"
  type        = map(list(string))
  default     = {}
}

variable "enable_dependencies" {
  description = "Enable stack dependencies for promotion chain (dev -> staging -> prod)"
  type        = bool
  default     = false
}

variable "opentofu_version" {
  description = "OpenTofu version to use (leave empty to use Spacelift default)"
  type        = string
  default     = ""
}

variable "administrative" {
  description = "Grant administrative privileges to stacks (use sparingly)"
  type        = bool
  default     = false
}

variable "protect_production" {
  description = "Enable additional protection for production stacks (manual approval required)"
  type        = bool
  default     = false
}

variable "autodeploy" {
  description = "Enable automatic deployment on git push"
  type        = bool
  default     = true
}
