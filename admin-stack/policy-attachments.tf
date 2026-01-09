# admin-stack/policy-attachments.tf

# Attach naming policy to all environments
resource "spacelift_policy_attachment" "naming_all" {
  policy_id = spacelift_policy.naming_convention.id
  space_id  = "root"
}

# Attach security policy to all environments
resource "spacelift_policy_attachment" "security_all" {
  policy_id = spacelift_policy.security.id
  space_id  = "root"
}

# Attach approval policy to production space only
resource "spacelift_policy_attachment" "approval_production" {
  policy_id = spacelift_policy.production_approval.id
  space_id  = spacelift_space.environment["production"].id
}

# Attach notification policy globally
resource "spacelift_policy_attachment" "notification_all" {
  policy_id = spacelift_policy.failure_notification.id
  space_id  = "root"
}
