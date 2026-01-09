# dashboard/app.py

from flask import Flask, render_template, jsonify
import sys
sys.path.append('../api-integration')
from spacelift_client import SpaceLiftClient, SpaceLiftConfig
import time
from functools import wraps

app = Flask(__name__)
client = SpaceLiftClient()

# Simple in-memory cache
cache = {}
cache_timestamps = {}
CACHE_TTL = 60  # seconds

def cached(ttl=CACHE_TTL):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            key = f"{func.__name__}:{str(args)}:{str(kwargs)}"
            now = time.time()
            
            if key in cache and now - cache_timestamps.get(key, 0) < ttl:
                return cache[key]
            
            result = func(*args, **kwargs)
            cache[key] = result
            cache_timestamps[key] = now
            return result
        return wrapper
    return decorator

@app.route('/')
def index():
    return render_template('dashboard.html')

@app.route('/api/overview')
@cached(ttl=30)
def api_overview():
    """System overview metrics"""
    stacks = client.list_stacks()
    
    total = len(stacks)
    healthy = sum(1 for s in stacks if s['state'] == 'FINISHED')
    failed = sum(1 for s in stacks if s['state'] == 'FAILED')
    running = sum(1 for s in stacks if s['state'] in ['QUEUED', 'PREPARING', 'RUNNING'])
    locked = sum(1 for s in stacks if s.get('lockedBy'))
    
    return jsonify({
        'total_stacks': total,
        'healthy': healthy,
        'failed': failed,
        'running': running,
        'locked': locked,
        'health_percentage': round((healthy / total) * 100, 1) if total > 0 else 0
    })

@app.route('/api/stacks')
@cached(ttl=30)
def api_stacks():
    """All stacks with status"""
    stacks = client.list_stacks()
    return jsonify([{
        'id': s['id'],
        'name': s['name'],
        'state': s['state'],
        'space': s.get('space', {}).get('name', 'root'),
        'labels': s.get('labels', []),
        'locked': bool(s.get('lockedBy'))
    } for s in stacks])

@app.route('/api/environments')
@cached(ttl=60)
def api_environments():
    """Environment health summary"""
    environments = ['development', 'staging', 'production']
    results = []
    
    for env in environments:
        status = client.get_environment_status(env)
        results.append(status)
    
    return jsonify(results)

@app.route('/api/recent-runs')
@cached(ttl=15)
def api_recent_runs():
    """Recent runs across all stacks"""
    query = """
    query {
        stacks {
            name
            runs(first: 3) {
                id
                state
                type
                createdAt
                finishedAt
                triggeredBy
                delta { addCount changeCount deleteCount }
            }
        }
    }
    """
    data = client.execute(query)
    
    all_runs = []
    for stack in data['stacks']:
        for run in stack.get('runs', []):
            run['stackName'] = stack['name']
            all_runs.append(run)
    
    all_runs.sort(key=lambda r: r['createdAt'], reverse=True)
    return jsonify(all_runs[:30])

@app.route('/api/stack/<stack_id>')
def api_stack_detail(stack_id):
    """Detailed stack information"""
    stack = client.get_stack(stack_id)
    return jsonify(stack)

@app.route('/api/stack/<stack_id>/trigger', methods=['POST'])
def api_trigger_run(stack_id):
    """Trigger a run for a stack"""
    try:
        run = client.trigger_run(stack_id)
        return jsonify({"success": True, "run": run})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)