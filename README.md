# Spacelift Advanced Patterns Lab

This repository contains the infrastructure code for the Spacelift Advanced Patterns training lab.

## Structure

- `admin-stack/` - Self-managing Spacelift configuration
- `stack-factory/` - Reusable stack factory module
- `environments/` - Environment-specific configurations
- `api-integration/` - API integration scripts
- `dashboard/` - Monitoring dashboard application
- `compliance/` - Policy and compliance automation

## Getting Started

1. Set up your Spacelift API credentials
2. Configure AWS access
3. Follow the lab guide

##############################################################################

# Advanced Spacelift Patterns with OpenTofu
## Hands-On Lab Guide

### Lab Overview

This hands-on lab guides you through implementing the five advanced Spacelift patterns covered in the tutorial. You'll build a complete infrastructure platform with self-managing capabilities, automated stack provisioning, API integrations, monitoring dashboards, and compliance automation.



**Lab Environment:**
- Spacelift account with admin access
- AWS account with appropriate permissions
- GitHub repository for code storage
- Local development environment with required tools

---

### Lab Setup

#### Prerequisites Verification


# Verify required tools
echo "=== Checking Prerequisites ==="

# OpenTofu
tofu version
# Expected: OpenTofu v1.6.0 or higher

# Python
python3 --version
# Expected: Python 3.8 or higher

# AWS CLI
aws --version
# Expected: aws-cli/2.x

# jq
jq --version
# Expected: jq-1.6 or higher

# curl
curl --version | head -1
# Expected: curl 7.x or higher

echo "=== All prerequisites verified ==="
```

#### Environment Setup

# Create lab directory structure
mkdir -p ~/spacelift-lab/{admin-stack,stack-factory,api-integration,dashboard,compliance}
cd ~/spacelift-lab

# Set environment variables
export SPACELIFT_API_ENDPOINT="https://YOUR-ORG.app.spacelift.io"
export SPACELIFT_API_KEY_ID="your-api-key-id"
export SPACELIFT_API_KEY_SECRET="your-api-key-secret"
export AWS_REGION="us-west-2"
export AWS_PROFILE="default"  # Or your profile name

# Verify Spacelift connectivity
curl -s "${SPACELIFT_API_ENDPOINT}/graphql" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { apiKeyUser(id: \"'${SPACELIFT_API_KEY_ID}'\", secret: \"'${SPACELIFT_API_KEY_SECRET}'\") { jwt } }"
  }' | jq -r '.data.apiKeyUser.jwt' > /dev/null && echo "✅ Spacelift connection verified" || echo "❌ Spacelift connection failed"

# Verify AWS connectivity
aws sts get-caller-identity && echo "✅ AWS connection verified" || echo "❌ AWS connection failed"
```

#### GitHub Repository Setup


# Initialize Git repository
cd ~/spacelift-lab
git init
git remote add origin git@github.com:YOUR-ORG/spacelift-lab.git

# Create initial structure
cat > README.md << 'EOF'
# Spacelift Advanced Patterns Lab

This repository contains the infrastructure code for the Spacelift Advanced Patterns training lab.

## Structure

- `admin-stack/` - Self-managing Spacelift configuration
- `stack-factory/` - Reusable stack factory module
- `environments/` - Environment-specific configurations
- `api-integration/` - API integration scripts
- `dashboard/` - Monitoring dashboard application
- `compliance/` - Policy and compliance automation

## Getting Started

1. Set up your Spacelift API credentials
2. Configure AWS access
3. Follow the lab guide

EOF

git add .
git commit -m "Initial lab setup"
git push -u origin main
```

---

### Phase 1: Admin Stack Foundation

**Objective:** Create the foundational admin stack that will manage all other Spacelift resources.

#### Step 1.4: Deploy Admin Stack


# Initialize and validate
cd ~/spacelift-lab/admin-stack
tofu init
tofu validate

# Plan changes
tofu plan -out=admin.tfplan

# Review the plan carefully
# You should see:
# - 3 environment spaces
# - 1 platform space  
# - 3 team spaces
# - AWS integration context
# - 3 environment contexts
# - Secrets context

# Apply if plan looks correct
tofu apply admin.tfplan

# Verify in Spacelift UI
echo "Verify resources at: ${SPACELIFT_API_ENDPOINT}"




**Checkpoint 1.1:** Verify the following in Spacelift UI:
- [ ] Space hierarchy visible (Platform, Development, Staging, Production)
- [ ] Team spaces under Development
- [ ] Contexts created with environment variables
- [ ] Admin stack created and connected to repository

---

### Phase 2: Stack Factory Implementation

**Objective:** Build a reusable module that automatically creates stacks based on configuration.


#### Step 2.4: Deploy and Verify


cd ~/spacelift-lab/admin-stack

# Update the module
tofu init -upgrade
tofu plan -out=stacks.tfplan

# Review - you should see:
# - web-application-development stack
# - web-application-staging stack
# - web-application-production stack
# - data-pipeline-development stack
# - data-pipeline-production stack
# - Stack dependencies

tofu apply stacks.tfplan
```

**Checkpoint 2.1:** Verify in Spacelift UI:
- [ ] All project stacks created
- [ ] Stacks in correct spaces
- [ ] Contexts attached to stacks
- [ ] Dependencies visible in stack settings
- [ ] Production stacks protected from deletion

---

### Phase 3: Policy Framework

**Objective:** Implement comprehensive policies for governance and compliance.

#### Step 3.3: Deploy and Test Policies


cd ~/spacelift-lab/admin-stack
tofu plan -out=policies.tfplan
tofu apply policies.tfplan

**Checkpoint 3.1:** Test policies by:
- [ ] Triggering a run with improper naming - verify denial
- [ ] Triggering a production run - verify approval requirement
- [ ] Creating a security group with 0.0.0.0/0 - verify warning/denial

---

### Phase 4: API Integration

**Objective:** Implement GraphQL API integration for automation and external tool connectivity.

#### Step 4.3: Test API Integration


cd ~/spacelift-lab/api-integration

# Install requirements
pip install requests

# Test list stacks
python spacelift_client.py list-stacks

# Test environment status
python spacelift_client.py status development

# Test triggering a run (use actual stack ID)
# python spacelift_client.py trigger-run web-application-development
```

**Checkpoint 4.1:** Verify API operations:
- [ ] Can list all stacks
- [ ] Can get stack details
- [ ] Can trigger runs
- [ ] Can check environment status
- [ ] Promotion script works end-to-end

---

### Phase 5: Dashboard Implementation

**Objective:** Build a monitoring dashboard using the API.

#### Step 5.3: Run Dashboard


cd ~/spacelift-lab/dashboard

# Install Flask
pip install flask

# Run dashboard
python app.py

# Open in browser: http://localhost:8080
```

**Checkpoint 5.1:** Dashboard functionality:
- [ ] Overview cards show correct counts
- [ ] Environment health displays correctly
- [ ] Recent runs table populates
- [ ] Stack list shows all stacks
- [ ] Trigger run button works

---

### Phase 6: Compliance Automation

**Objective:** Implement comprehensive compliance scanning and reporting.

#### Step 6.1: Create Compliance Scanner

mkdir -p ~/spacelift-lab/compliance
cd ~/spacelift-lab/compliance

#### Step 6.2: Run Compliance Scan


cd ~/spacelift-lab/compliance
python scanner.py
```

**Checkpoint 6.1:** Compliance automation:
- [ ] Scanner runs without errors
- [ ] Violations correctly identified
- [ ] Report generated in both formats
- [ ] Critical issues highlighted

---

### Lab Cleanup

# Clean up AWS resources
cd ~/spacelift-lab/admin-stack
tofu destroy

# Or selectively remove stacks via API
python ~/spacelift-lab/api-integration/spacelift_client.py list-stacks

---

### Summary

In this lab, you have implemented:

1. **Admin Stack Pattern** - Self-managing Spacelift configuration with space hierarchy, contexts, and the admin stack itself
2. **Stack Factory** - Reusable module for automated stack creation across environments
3. **Policy Framework** - Comprehensive policies for naming, security, and approvals
4. **API Integration** - Python client for automation and external tool integration
5. **Operations Dashboard** - Real-time monitoring interface using Flask
6. **Compliance Automation** - Automated scanning and reporting

These patterns form the foundation of an enterprise-grade infrastructure platform that enables self-service, ensures governance, and provides comprehensive observability.