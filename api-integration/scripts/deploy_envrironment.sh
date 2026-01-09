# api-integration/scripts/deploy_environment.sh
#!/bin/bash

# Deploy all stacks in an environment with proper sequencing

set -e

ENVIRONMENT=${1:-development}
WAIT_FOR_COMPLETION=${2:-true}

echo "=== Deploying ${ENVIRONMENT} environment ==="

# Get stacks for environment
python3 << EOF
import json
from spacelift_client import SpaceLiftClient

client = SpaceLiftClient()
results = client.trigger_environment_deployment("${ENVIRONMENT}")

print("\n=== Deployment Results ===")
for r in results:
    if r['status'] == 'triggered':
        print(f"✅ {r['stack']}: Run {r['run_id']}")
    else:
        print(f"❌ {r['stack']}: {r.get('error', 'Unknown error')}")
EOF

if [ "$WAIT_FOR_COMPLETION" = "true" ]; then
    echo ""
    echo "=== Waiting for runs to complete ==="
    # Would implement wait logic here
fi