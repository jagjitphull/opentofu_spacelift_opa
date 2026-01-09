# admin-stack/policies.tf

# Naming convention policy
resource "spacelift_policy" "naming_convention" {
  name     = "enforce-naming-convention"
  type     = "PLAN"
  space_id = spacelift_space.platform.id
  labels   = ["governance", "naming", "required"]

  body = <<-REGO
    package spacelift

    import future.keywords.in
    import future.keywords.if

    # Get environment from stack labels
    get_environment := env if {
      env := input.spacelift.stack.labels[_]
      env in ["development", "staging", "production"]
    }

    # Environment prefixes
    env_prefixes := {
      "development": "dev-",
      "staging": "stg-",
      "production": "prd-"
    }

    # Resources that need naming enforcement
    naming_required := {
      "aws_instance",
      "aws_s3_bucket", 
      "aws_rds_instance",
      "aws_elasticache_cluster",
      "aws_eks_cluster"
    }

    # Deny resources without proper naming prefix
    deny[msg] if {
      resource := input.terraform.resource_changes[_]
      resource.change.actions[_] == "create"
      resource.type in naming_required
      
      env := get_environment
      required_prefix := env_prefixes[env]
      
      # Check bucket naming (no tags for S3)
      resource.type == "aws_s3_bucket"
      bucket_name := resource.change.after.bucket
      not startswith(bucket_name, required_prefix)
      
      msg := sprintf(
        "S3 bucket '%s' must start with prefix '%s' for %s environment",
        [bucket_name, required_prefix, env]
      )
    }

    deny[msg] if {
      resource := input.terraform.resource_changes[_]
      resource.change.actions[_] == "create"
      resource.type in naming_required
      resource.type != "aws_s3_bucket"
      
      env := get_environment
      required_prefix := env_prefixes[env]
      
      # Check Name tag
      name := resource.change.after.tags.Name
      not startswith(name, required_prefix)
      
      msg := sprintf(
        "Resource %s Name tag '%s' must start with prefix '%s' for %s environment",
        [resource.address, name, required_prefix, env]
      )
    }

    # Warn on missing required tags
    warn[msg] if {
      resource := input.terraform.resource_changes[_]
      resource.change.actions[_] == "create"
      
      # Resources that should be tagged
      taggable := {
        "aws_instance", "aws_s3_bucket", "aws_rds_instance",
        "aws_vpc", "aws_subnet", "aws_security_group"
      }
      resource.type in taggable
      
      required := {"Environment", "Project", "ManagedBy"}
      provided := {tag | resource.change.after.tags[tag]}
      missing := required - provided
      count(missing) > 0
      
      msg := sprintf(
        "Resource %s is missing recommended tags: %v",
        [resource.address, missing]
      )
    }
  REGO
}

# Security policy - block dangerous configurations
resource "spacelift_policy" "security" {
  name     = "security-requirements"
  type     = "PLAN"
  space_id = spacelift_space.platform.id
  labels   = ["governance", "security", "required"]

  body = <<-REGO
    package spacelift

    import future.keywords.in
    import future.keywords.if

    # Block public S3 buckets
    deny[msg] if {
      resource := input.terraform.resource_changes[_]
      resource.change.actions[_] == "create"
      resource.type == "aws_s3_bucket_public_access_block"
      
      after := resource.change.after
      not after.block_public_acls
      
      msg := "S3 buckets must block public ACLs"
    }

    deny[msg] if {
      resource := input.terraform.resource_changes[_]
      resource.change.actions[_] == "create"
      resource.type == "aws_s3_bucket_public_access_block"
      
      after := resource.change.after
      not after.block_public_policy
      
      msg := "S3 buckets must block public policies"
    }

    # Block unencrypted RDS instances
    deny[msg] if {
      resource := input.terraform.resource_changes[_]
      resource.change.actions[_] == "create"
      resource.type == "aws_rds_instance"
      
      not resource.change.after.storage_encrypted
      
      msg := sprintf(
        "RDS instance %s must have encryption enabled",
        [resource.address]
      )
    }

    # Block SSH from anywhere
    deny[msg] if {
      resource := input.terraform.resource_changes[_]
      resource.change.actions[_] == "create"
      resource.type == "aws_security_group_rule"
      
      resource.change.after.type == "ingress"
      resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
      resource.change.after.from_port <= 22
      resource.change.after.to_port >= 22
      
      msg := sprintf(
        "Security group rule %s allows SSH (port 22) from 0.0.0.0/0 - this is not allowed",
        [resource.address]
      )
    }

    # Block RDP from anywhere  
    deny[msg] if {
      resource := input.terraform.resource_changes[_]
      resource.change.actions[_] == "create"
      resource.type == "aws_security_group_rule"
      
      resource.change.after.type == "ingress"
      resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
      resource.change.after.from_port <= 3389
      resource.change.after.to_port >= 3389
      
      msg := sprintf(
        "Security group rule %s allows RDP (port 3389) from 0.0.0.0/0 - this is not allowed",
        [resource.address]
      )
    }

    # Warn on any 0.0.0.0/0 ingress
    warn[msg] if {
      resource := input.terraform.resource_changes[_]
      resource.change.actions[_] == "create"
      resource.type == "aws_security_group_rule"
      
      resource.change.after.type == "ingress"
      resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
      
      msg := sprintf(
        "Security group rule %s has ingress from 0.0.0.0/0 - ensure this is intentional",
        [resource.address]
      )
    }
  REGO
}

# Approval policy for production
resource "spacelift_policy" "production_approval" {
  name     = "production-requires-approval"
  type     = "APPROVAL"
  space_id = spacelift_space.environment["production"].id
  labels   = ["governance", "approval", "production"]

  body = <<-REGO
    package spacelift

    import future.keywords.if

    # Never auto-approve production
    approve if {
      false
    }

    # Require at least one approval for production
    reject[reason] if {
      count(input.reviews.current.approvals) < 1
      reason := "Production changes require at least one approval"
    }

    # Reject if there are any denials
    reject[reason] if {
      count(input.reviews.current.rejections) > 0
      reason := "This change has been rejected by a reviewer"
    }
  REGO
}

# Notification policy for failures
resource "spacelift_policy" "failure_notification" {
  name     = "notify-on-failure"
  type     = "NOTIFICATION"
  space_id = spacelift_space.platform.id
  labels   = ["notification", "alerting"]

  body = <<-REGO
    package spacelift

    import future.keywords.if

    # Webhook notification on failure
    webhook[{"endpoint_id": endpoint, "payload": payload}] if {
      input.run.state == "FAILED"
      
      # Replace with your webhook endpoint ID
      endpoint := "your-webhook-endpoint-id"
      
      payload := {
        "event_type": "spacelift.run.failed",
        "stack_name": input.run.stack.name,
        "stack_id": input.run.stack.id,
        "run_id": input.run.id,
        "triggered_by": input.run.triggered_by,
        "commit_sha": input.run.commit.hash,
        "commit_message": input.run.commit.message,
        "timestamp": input.run.created_at
      }
    }

    # Also notify on drift detection
    webhook[{"endpoint_id": endpoint, "payload": payload}] if {
      input.run.type == "DRIFT_DETECTION"
      input.run.state == "FINISHED"
      
      # Check if drift was detected
      input.run.delta.total > 0
      
      endpoint := "your-webhook-endpoint-id"
      
      payload := {
        "event_type": "spacelift.drift.detected",
        "stack_name": input.run.stack.name,
        "changes": input.run.delta.total,
        "timestamp": input.run.created_at
      }
    }
  REGO
}
