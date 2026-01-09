# api-integration/spacelift_client.py

import os
import requests
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime, timedelta
import json
import time

@dataclass
class SpaceLiftConfig:
    endpoint: str
    api_key_id: str
    api_key_secret: str
    
    @classmethod
    def from_env(cls) -> 'SpaceLiftConfig':
        return cls(
            endpoint=os.environ['SPACELIFT_API_ENDPOINT'],
            api_key_id=os.environ['SPACELIFT_API_KEY_ID'],
            api_key_secret=os.environ['SPACELIFT_API_KEY_SECRET']
        )


class SpaceLiftClient:
    def __init__(self, config: Optional[SpaceLiftConfig] = None):
        self.config = config or SpaceLiftConfig.from_env()
        self.graphql_url = f"{self.config.endpoint}/graphql"
        self._token: Optional[str] = None
        self._token_expiry: Optional[datetime] = None
    
    def _get_token(self) -> str:
        """Get or refresh JWT token"""
        if self._token and self._token_expiry and datetime.now() < self._token_expiry:
            return self._token
        
        query = """
        mutation GetToken($id: ID!, $secret: String!) {
            apiKeyUser(id: $id, secret: $secret) {
                jwt
            }
        }
        """
        
        response = requests.post(
            self.graphql_url,
            json={
                "query": query,
                "variables": {
                    "id": self.config.api_key_id,
                    "secret": self.config.api_key_secret
                }
            }
        )
        response.raise_for_status()
        
        data = response.json()
        if 'errors' in data:
            raise Exception(f"Authentication failed: {data['errors']}")
        
        self._token = data['data']['apiKeyUser']['jwt']
        self._token_expiry = datetime.now() + timedelta(minutes=50)
        
        return self._token
    
    def execute(self, query: str, variables: Optional[Dict] = None) -> Dict:
        """Execute GraphQL query/mutation"""
        headers = {
            "Authorization": f"Bearer {self._get_token()}",
            "Content-Type": "application/json"
        }
        
        payload = {"query": query}
        if variables:
            payload["variables"] = variables
        
        response = requests.post(self.graphql_url, json=payload, headers=headers)
        response.raise_for_status()
        
        result = response.json()
        if 'errors' in result:
            raise Exception(f"GraphQL errors: {json.dumps(result['errors'], indent=2)}")
        
        return result['data']
    
    # ===== STACK OPERATIONS =====
    
    def list_stacks(self) -> List[Dict]:
        """List all stacks"""
        query = """
        query {
            stacks {
                id
                name
                description
                state
                labels
                lockedBy
                space { id name }
            }
        }
        """
        return self.execute(query)['stacks']
    
    def get_stack(self, stack_id: str) -> Dict:
        """Get detailed stack information"""
        query = """
        query GetStack($id: ID!) {
            stack(id: $id) {
                id
                name
                description
                repository
                branch
                projectRoot
                state
                lockedBy
                labels
                autodeploy
                runs(first: 10) {
                    id
                    state
                    type
                    createdAt
                    finishedAt
                    triggeredBy
                    delta { addCount changeCount deleteCount }
                }
                resources {
                    id
                    address
                    type
                }
            }
        }
        """
        return self.execute(query, {"id": stack_id})['stack']
    
    def get_stacks_by_label(self, label: str) -> List[Dict]:
        """Get all stacks with a specific label"""
        stacks = self.list_stacks()
        return [s for s in stacks if label in s.get('labels', [])]
    
    # ===== RUN OPERATIONS =====
    
    def trigger_run(self, stack_id: str, commit_sha: Optional[str] = None) -> Dict:
        """Trigger a new run"""
        query = """
        mutation TriggerRun($stackId: ID!, $commitSha: String) {
            runTrigger(stack: $stackId, commitSha: $commitSha) {
                id
                state
                createdAt
            }
        }
        """
        return self.execute(query, {"stackId": stack_id, "commitSha": commit_sha})['runTrigger']
    
    def confirm_run(self, run_id: str) -> Dict:
        """Confirm/approve a run for apply"""
        query = """
        mutation ConfirmRun($id: ID!) {
            runConfirm(id: $id) {
                id
                state
            }
        }
        """
        return self.execute(query, {"id": run_id})['runConfirm']
    
    def cancel_run(self, run_id: str, note: str = "") -> Dict:
        """Cancel a run"""
        query = """
        mutation CancelRun($id: ID!, $note: String) {
            runCancel(id: $id, note: $note) {
                id
                state
            }
        }
        """
        return self.execute(query, {"id": run_id, "note": note})['runCancel']
    
    def get_run(self, run_id: str) -> Dict:
        """Get run details"""
        query = """
        query GetRun($id: ID!) {
            run(id: $id) {
                id
                state
                type
                createdAt
                finishedAt
                triggeredBy
                delta { addCount changeCount deleteCount }
                policyReceipts {
                    policy { name type }
                    outcome
                    denies
                    warnings
                }
            }
        }
        """
        return self.execute(query, {"id": run_id})['run']
    
    def wait_for_run(
        self, 
        run_id: str, 
        timeout: int = 600, 
        poll_interval: int = 10,
        terminal_states: Optional[set] = None
    ) -> Dict:
        """Wait for run to reach terminal state"""
        if terminal_states is None:
            terminal_states = {'FINISHED', 'FAILED', 'CANCELED', 'DISCARDED'}
        
        start = time.time()
        
        while time.time() - start < timeout:
            run = self.get_run(run_id)
            print(f"  Run state: {run['state']}")
            
            if run['state'] in terminal_states:
                return run
            
            # Also break on waiting for confirmation
            if run['state'] == 'UNCONFIRMED':
                return run
            
            time.sleep(poll_interval)
        
        raise TimeoutError(f"Run {run_id} did not complete within {timeout}s")
    
    # ===== LOCK OPERATIONS =====
    
    def lock_stack(self, stack_id: str, note: str = "") -> Dict:
        """Lock a stack"""
        query = """
        mutation LockStack($id: ID!, $note: String) {
            stackLock(id: $id, note: $note) {
                id
                lockedBy
            }
        }
        """
        return self.execute(query, {"id": stack_id, "note": note})['stackLock']
    
    def unlock_stack(self, stack_id: str) -> Dict:
        """Unlock a stack"""
        query = """
        mutation UnlockStack($id: ID!) {
            stackUnlock(id: $id) {
                id
                lockedBy
            }
        }
        """
        return self.execute(query, {"id": stack_id})['stackUnlock']
    
    # ===== BATCH OPERATIONS =====
    
    def trigger_environment_deployment(self, environment: str) -> List[Dict]:
        """Trigger runs for all stacks in an environment"""
        stacks = self.get_stacks_by_label(environment)
        results = []
        
        for stack in stacks:
            try:
                run = self.trigger_run(stack['id'])
                results.append({
                    "stack": stack['name'],
                    "stack_id": stack['id'],
                    "run_id": run['id'],
                    "status": "triggered"
                })
                print(f"✅ Triggered run for {stack['name']}: {run['id']}")
            except Exception as e:
                results.append({
                    "stack": stack['name'],
                    "stack_id": stack['id'],
                    "error": str(e),
                    "status": "failed"
                })
                print(f"❌ Failed to trigger {stack['name']}: {e}")
        
        return results
    
    def get_environment_status(self, environment: str) -> Dict:
        """Get health status for an environment"""
        stacks = self.get_stacks_by_label(environment)
        
        healthy = sum(1 for s in stacks if s['state'] == 'FINISHED')
        failed = sum(1 for s in stacks if s['state'] == 'FAILED')
        running = sum(1 for s in stacks if s['state'] in ['QUEUED', 'PREPARING', 'RUNNING'])
        locked = sum(1 for s in stacks if s.get('lockedBy'))
        
        return {
            "environment": environment,
            "total": len(stacks),
            "healthy": healthy,
            "failed": failed,
            "running": running,
            "locked": locked,
            "health_percentage": round((healthy / len(stacks)) * 100, 1) if stacks else 0,
            "stacks": [{
                "name": s['name'],
                "state": s['state'],
                "locked": bool(s.get('lockedBy'))
            } for s in stacks]
        }


# CLI usage
if __name__ == "__main__":
    import sys
    
    client = SpaceLiftClient()
    
    if len(sys.argv) < 2:
        print("Usage: python spacelift_client.py <command> [args]")
        print("Commands: list-stacks, get-stack, trigger-run, status")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "list-stacks":
        stacks = client.list_stacks()
        for s in stacks:
            print(f"{s['name']}: {s['state']} (space: {s.get('space', {}).get('name', 'root')})")
    
    elif command == "get-stack":
        if len(sys.argv) < 3:
            print("Usage: python spacelift_client.py get-stack <stack-id>")
            sys.exit(1)
        stack = client.get_stack(sys.argv[2])
        print(json.dumps(stack, indent=2))
    
    elif command == "trigger-run":
        if len(sys.argv) < 3:
            print("Usage: python spacelift_client.py trigger-run <stack-id>")
            sys.exit(1)
        run = client.trigger_run(sys.argv[2])
        print(f"Triggered run: {run['id']}")
    
    elif command == "status":
        if len(sys.argv) < 3:
            print("Usage: python spacelift_client.py status <environment>")
            sys.exit(1)
        status = client.get_environment_status(sys.argv[2])
        print(json.dumps(status, indent=2))
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)