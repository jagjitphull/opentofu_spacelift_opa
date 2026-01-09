# compliance/scanner.py

import sys
sys.path.append('../api-integration')
from spacelift_client import SpaceLiftClient
from dataclasses import dataclass
from typing import List, Dict, Optional, Callable
from datetime import datetime, timedelta
import json

@dataclass
class ComplianceViolation:
    check_name: str
    severity: str  # critical, high, medium, low
    stack_id: str
    stack_name: str
    description: str
    details: Dict
    timestamp: datetime

@dataclass
class ComplianceCheck:
    name: str
    description: str
    severity: str
    checker: Callable

class ComplianceScanner:
    def __init__(self):
        self.client = SpaceLiftClient()
        self.checks: List[ComplianceCheck] = []
        self._register_default_checks()
    
    def _register_default_checks(self):
        """Register all default compliance checks"""
        
        # Check 1: Production drift detection
        self.add_check(ComplianceCheck(
            name="production-drift-detection",
            description="Production stacks must have drift detection enabled",
            severity="high",
            checker=self._check_drift_detection
        ))
        
        # Check 2: Policy attachment
        self.add_check(ComplianceCheck(
            name="policy-attached",
            description="All stacks must have at least one policy attached",
            severity="critical",
            checker=self._check_policy_attachment
        ))
        
        # Check 3: No stale locks
        self.add_check(ComplianceCheck(
            name="no-stale-locks",
            description="Stacks should not be locked for extended periods",
            severity="medium",
            checker=self._check_stale_locks
        ))
        
        # Check 4: Recent successful deployment
        self.add_check(ComplianceCheck(
            name="recent-deployment",
            description="Production stacks should have recent successful deployments",
            severity="high",
            checker=self._check_recent_deployment
        ))
        
        # Check 5: No failed state
        self.add_check(ComplianceCheck(
            name="no-failed-stacks",
            description="Stacks should not be in failed state",
            severity="high",
            checker=self._check_failed_state
        ))
    
    def add_check(self, check: ComplianceCheck):
        self.checks.append(check)
    
    def _get_detailed_stacks(self) -> List[Dict]:
        """Get stacks with detailed information"""
        query = """
        query {
            stacks {
                id
                name
                labels
                state
                lockedBy
                attachedPolicies { id name }
                runs(first: 5) {
                    state
                    createdAt
                    type
                }
            }
        }
        """
        return self.client.execute(query)['stacks']
    
    def _check_drift_detection(self, stack: Dict) -> Optional[ComplianceViolation]:
        """Check if production stacks have drift detection"""
        if 'production' not in stack.get('labels', []):
            return None
        
        # Note: Would need additional query for drift settings
        # Simplified check based on recent drift runs
        runs = stack.get('runs', [])
        has_drift_runs = any(r['type'] == 'DRIFT_DETECTION' for r in runs)
        
        if not has_drift_runs:
            return ComplianceViolation(
                check_name="production-drift-detection",
                severity="high",
                stack_id=stack['id'],
                stack_name=stack['name'],
                description="No drift detection runs found for production stack",
                details={"last_5_runs": [r['type'] for r in runs]},
                timestamp=datetime.now()
            )
        return None
    
    def _check_policy_attachment(self, stack: Dict) -> Optional[ComplianceViolation]:
        """Check that stacks have policies attached"""
        policies = stack.get('attachedPolicies', [])
        
        if not policies:
            return ComplianceViolation(
                check_name="policy-attached",
                severity="critical",
                stack_id=stack['id'],
                stack_name=stack['name'],
                description="Stack has no policies attached",
                details={},
                timestamp=datetime.now()
            )
        return None
    
    def _check_stale_locks(self, stack: Dict) -> Optional[ComplianceViolation]:
        """Check for stacks that have been locked"""
        if stack.get('lockedBy'):
            return ComplianceViolation(
                check_name="no-stale-locks",
                severity="medium",
                stack_id=stack['id'],
                stack_name=stack['name'],
                description="Stack is currently locked",
                details={"locked_by": stack['lockedBy']},
                timestamp=datetime.now()
            )
        return None
    
    def _check_recent_deployment(self, stack: Dict) -> Optional[ComplianceViolation]:
        """Check for recent successful deployment in production"""
        if 'production' not in stack.get('labels', []):
            return None
        
        runs = stack.get('runs', [])
        successful = [r for r in runs if r['state'] == 'FINISHED' and r['type'] == 'TRACKED']
        
        if not successful:
            return ComplianceViolation(
                check_name="recent-deployment",
                severity="high",
                stack_id=stack['id'],
                stack_name=stack['name'],
                description="No recent successful deployments found",
                details={"recent_runs": len(runs)},
                timestamp=datetime.now()
            )
        
        # Check if last success was within 30 days
        last_success = datetime.fromisoformat(successful[0]['createdAt'].replace('Z', '+00:00'))
        if datetime.now(last_success.tzinfo) - last_success > timedelta(days=30):
            return ComplianceViolation(
                check_name="recent-deployment",
                severity="high",
                stack_id=stack['id'],
                stack_name=stack['name'],
                description="Last successful deployment was over 30 days ago",
                details={"last_success": last_success.isoformat()},
                timestamp=datetime.now()
            )
        
        return None
    
    def _check_failed_state(self, stack: Dict) -> Optional[ComplianceViolation]:
        """Check for stacks in failed state"""
        if stack['state'] == 'FAILED':
            return ComplianceViolation(
                check_name="no-failed-stacks",
                severity="high",
                stack_id=stack['id'],
                stack_name=stack['name'],
                description="Stack is in FAILED state",
                details={"state": stack['state']},
                timestamp=datetime.now()
            )
        return None
    
    def scan(self, label_filter: Optional[str] = None) -> List[ComplianceViolation]:
        """Run all compliance checks"""
        violations = []
        stacks = self._get_detailed_stacks()
        
        if label_filter:
            stacks = [s for s in stacks if label_filter in s.get('labels', [])]
        
        for stack in stacks:
            for check in self.checks:
                violation = check.checker(stack)
                if violation:
                    violations.append(violation)
        
        return violations
    
    def scan_by_severity(self) -> Dict[str, List[ComplianceViolation]]:
        """Scan and group results by severity"""
        violations = self.scan()
        
        result = {"critical": [], "high": [], "medium": [], "low": []}
        for v in violations:
            result[v.severity].append(v)
        
        return result


def generate_report(scanner: ComplianceScanner, format: str = "text") -> str:
    """Generate compliance report"""
    violations = scanner.scan_by_severity()
    
    total = sum(len(v) for v in violations.values())
    
    if format == "json":
        return json.dumps({
            "generated_at": datetime.now().isoformat(),
            "summary": {
                "total": total,
                "critical": len(violations["critical"]),
                "high": len(violations["high"]),
                "medium": len(violations["medium"]),
                "low": len(violations["low"])
            },
            "violations": {
                sev: [{
                    "check": v.check_name,
                    "stack": v.stack_name,
                    "description": v.description,
                    "details": v.details
                } for v in viols]
                for sev, viols in violations.items()
            }
        }, indent=2)
    
    # Text format
    lines = [
        "=" * 60,
        "SPACELIFT COMPLIANCE REPORT",
        f"Generated: {datetime.now().isoformat()}",
        "=" * 60,
        "",
        "SUMMARY",
        "-" * 40,
        f"Total Violations: {total}",
        f"  Critical: {len(violations['critical'])}",
        f"  High:     {len(violations['high'])}",
        f"  Medium:   {len(violations['medium'])}",
        f"  Low:      {len(violations['low'])}",
        ""
    ]
    
    for severity in ["critical", "high", "medium", "low"]:
        viols = violations[severity]
        if viols:
            lines.extend([
                f"{severity.upper()} VIOLATIONS",
                "-" * 40
            ])
            for v in viols:
                lines.extend([
                    f"  Stack: {v.stack_name}",
                    f"  Check: {v.check_name}",
                    f"  Issue: {v.description}",
                    ""
                ])
    
    if total == 0:
        lines.append("✅ No compliance violations found!")
    
    return "\n".join(lines)


if __name__ == "__main__":
    scanner = ComplianceScanner()
    
    print("Running compliance scan...\n")
    report = generate_report(scanner, format="text")
    print(report)
    
    # Also save JSON report
    json_report = generate_report(scanner, format="json")
    with open("compliance_report.json", "w") as f:
        f.write(json_report)
    print("\nJSON report saved to compliance_report.json")
