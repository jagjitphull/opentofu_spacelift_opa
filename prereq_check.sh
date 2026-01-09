#!/bin/bash
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