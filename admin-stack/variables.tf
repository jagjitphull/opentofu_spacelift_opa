# variables.tf
variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "training-org"
}

variable "environments" {
  description = "List of environments to create"
  type        = list(string)
  default     = ["development", "staging", "production"]
}

variable "teams" {
  description = "Map of team configurations"
  type = map(object({
    name        = string
    description = string
    members     = list(string)
  }))
  default = {
    "platform" = {
      name        = "Platform Team"
      description = "Platform engineering team"
      members     = ["platform-lead", "platform-engineer"]
    }
    "alpha" = {
      name        = "Team Alpha"
      description = "Application team Alpha"
      members     = ["alpha-lead", "alpha-dev1", "alpha-dev2"]
    }
    "beta" = {
      name        = "Team Beta"
      description = "Application team Beta"
      members     = ["beta-lead", "beta-dev1"]
    }
  }
}

variable "github_namespace" {
  description = "GitHub organization or user namespace"
  type        = string
  default     = "your-org"
}

variable "repository_name" {
  description = "Repository name for infrastructure code"
  type        = string
  default     = "spacelift-lab"
}


variable "branch" {
  description = "Git branch to track"
  type        = string
  default     = "main"
}
