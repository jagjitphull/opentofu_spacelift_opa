# api-integration/scripts/promote_to_production.py
#!/usr/bin/env python3
"""
Promote changes from staging to production with safety checks.
"""

import sys
import json
from spacelift_client import SpaceLiftClient

def check_staging_health(client: SpaceLiftClient) -> bool:
    """Verify staging is healthy before promotion"""
    status = client.get_environment_status("staging")
    
    if status['failed'] > 0:
        print(f"❌ Staging has {status['failed']} failed stacks")
        return False
    
    if status['health_percentage'] < 100:
        print(f"⚠️  Staging health: {status['health_percentage']}%")
        return False
    
    print(f"✅ Staging health: {status['health_percentage']}%")
    return True

def get_promotion_candidates(client: SpaceLiftClient) -> list:
    """Find production stacks that need updates"""
    staging_stacks = client.get_stacks_by_label("staging")
    production_stacks = client.get_stacks_by_label("production")
    
    candidates = []
    for prod_stack in production_stacks:
        # Find matching staging stack
        base_name = prod_stack['name'].replace("-production", "")
        staging_name = f"{base_name}-staging"
        
        staging_match = next(
            (s for s in staging_stacks if s['name'] == staging_name),
            None
        )
        
        if staging_match:
            candidates.append({
                "production": prod_stack,
                "staging": staging_match
            })
    
    return candidates

def promote_stack(client: SpaceLiftClient, prod_stack: dict) -> dict:
    """Trigger production deployment"""
    print(f"  Triggering {prod_stack['name']}...")
    run = client.trigger_run(prod_stack['id'])
    print(f"  Run ID: {run['id']}")
    return run

def main():
    client = SpaceLiftClient()
    
    print("=== Production Promotion Workflow ===\n")
    
    # Step 1: Check staging health
    print("Step 1: Checking staging health...")
    if not check_staging_health(client):
        print("\n❌ Promotion blocked: Staging not healthy")
        sys.exit(1)
    
    # Step 2: Find promotion candidates
    print("\nStep 2: Finding promotion candidates...")
    candidates = get_promotion_candidates(client)
    
    if not candidates:
        print("No stacks to promote")
        sys.exit(0)
    
    print(f"Found {len(candidates)} stacks to promote:")
    for c in candidates:
        print(f"  - {c['production']['name']}")
    
    # Step 3: Confirm promotion
    print("\nStep 3: Confirm promotion")
    response = input("Proceed with promotion? [y/N]: ")
    if response.lower() != 'y':
        print("Promotion cancelled")
        sys.exit(0)
    
    # Step 4: Trigger production runs
    print("\nStep 4: Triggering production runs...")
    runs = []
    for c in candidates:
        run = promote_stack(client, c['production'])
        runs.append({
            "stack": c['production']['name'],
            "run_id": run['id']
        })
    
    print("\n=== Promotion Initiated ===")
    print("Production runs require approval. Review in Spacelift UI:")
    for r in runs:
        print(f"  {r['stack']}: {r['run_id']}")
    
    print("\n⚠️  Remember to approve runs in Spacelift UI")

if __name__ == "__main__":
    main()