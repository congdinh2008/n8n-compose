# 40. Best Practices - N8N

## 📋 Mục lục
- [Workflow Design](#workflow-design)
- [Naming Conventions](#naming-conventions)
- [Error Handling](#error-handling)
- [Performance Optimization](#performance-optimization)
- [Security](#security)
- [Maintenance](#maintenance)
- [Testing](#testing)
- [Documentation](#documentation)
- [Common Anti-Patterns](#common-anti-patterns)

---

## Workflow Design

### 1. Keep Workflows Simple

**Nguyên tắc:**
- Mỗi workflow nên làm MỘT việc cụ thể
- Nếu workflow > 15 nodes → xem xét tách
- Dùng sub-workflows cho logic phức tạp

**✅ Good:**

```
[Workflow 1: Lead Processing]
  Form → Validate → Create CRM → Notify

[Workflow 2: Lead Follow-up]
  Schedule → Check Due → Send Reminder

[Workflow 1] triggers [Workflow 2] via Execute Workflow node
```

**❌ Bad:**

```
[Mega Workflow]
  Form → Validate → Create → Update → Email → Slack → 
  Report → Cleanup → Archive → Follow-up → Remind → ...
  (50+ nodes, hard to maintain)
```

### 2. Use Modular Design

```
┌──────────────────────────────────────┐
│          Parent Workflow             │
│                                      │
│  [Trigger] → [Execute Workflow A]   │
│                ↓                     │
│           [Execute Workflow B]       │
│                ↓                     │
│           [Execute Workflow C]       │
└──────────────────────────────────────┘

Benefits:
- Reusable components
- Easier testing
- Clearer responsibility
- Independent deployment
```

### 3. Flow Control Patterns

**Fan-out Pattern:**

```
         [Source]
        /    |    \
       ↓     ↓     ↓
    [A]    [B]    [C]
     |      |      |
     ↓      ↓      ↓
    [D]    [E]    [F]
```

**Fan-in Pattern:**

```
    [A]    [B]    [C]
     |      |      |
     ↓      ↓      ↓
      \     |     /
       \    |    /
        [Merge]
           ↓
       [Process]
```

**Circuit Breaker:**

```
[Task] → [If Success?]
            ↓       ↓
         [Yes]    [No]
          ↓        ↓
      [Continue] [Alert + Stop]
```

---

## Naming Conventions

### Workflow Names

**Format:** `[Type] - [Description] - [Frequency/Trigger]`

| ✅ Good | ❌ Bad |
|---------|--------|
| `[CRM] Lead Processing - Webhook` | `workflow1` |
| `[Email] Daily Digest - Schedule 9AM` | `email thing` |
| `[Sync] HubSpot → DB - Hourly` | `sync` |
| `[Report] Weekly Sales - Monday` | `report` |

### Node Names

**Format:** `[Action] - [Target/Service]`

| ✅ Good | ❌ Bad |
|---------|--------|
| `Create - HubSpot Contact` | `HTTP Request` |
| `Send - Slack Notification` | `Slack` |
| `Query - PostgreSQL Users` | `Postgres` |
| `Validate - Email Format` | `Code` |

### Credentials Names

**Format:** `[Service] - [Environment] - [Purpose]`

| ✅ Good | ❌ Bad |
|---------|--------|
| `HubSpot - Production - CRM` | `API Key 1` |
| `PostgreSQL - Staging - Analytics` | `Database` |
| `Slack - Production - Alerts` | `Webhook` |

### Variables và Fields

```javascript
// ✅ Descriptive
const customerEmail = $json.email;
const orderTotal = $json.total_amount;
const processingDate = $now.toFormat('yyyy-MM-dd');

// ❌ Unclear
const e = $json.e;
const t = $json.t;
const d = $now;
```

### Tags

Use consistent tag taxonomy:

| Tag | Usage |
|-----|-------|
| `production` | Live workflows |
| `development` | Testing workflows |
| `critical` | Business-critical workflows |
| `reporting` | Report generation |
| `sync` | Data synchronization |
| `notification` | Alert/notification workflows |
| `crm` | CRM-related workflows |
| `finance` | Finance-related workflows |

---

## Error Handling

### 1. Always Handle Errors

**Every workflow should have:**

```
[Main Flow]
     │
     ├──error──► [Error Handler]
     │              │
     │              ▼
     │         [Log Error]
     │              │
     │              ▼
     │         [Notify Team]
     │              │
     │              ▼
     │         [Attempt Recovery]
```

### 2. Error Handler Workflow

```json
{
  "name": "Error Handler Template",
  "nodes": [
    {
      "name": "Error Trigger",
      "type": "n8n-nodes-base.errorTrigger"
    },
    {
      "name": "Extract Error Info",
      "type": "n8n-nodes-base.code",
      "parameters": {
        "jsCode": "return {\n  json: {\n    workflow: $triggerData.workflow.name,\n    error: $triggerData.error.message,\n    node: $triggerData.error.node?.name,\n    timestamp: new Date().toISOString(),\n    execution_id: $triggerData.execution.id\n  }\n};"
      }
    },
    {
      "name": "Log to Database",
      "type": "n8n-nodes-base.postgres"
    },
    {
      "name": "Send Alert",
      "type": "n8n-nodes-base.slack"
    }
  ]
}
```

### 3. Retry Strategy

**For flaky APIs:**

```
[HTTP Request]
     │
     ├──fail──► [Wait 30s]
     │             │
     │             ▼
     │        [Retry 1]
     │             │
     │             ├──fail──► [Wait 5m]
     │             │             │
     │             │             ▼
     │             │        [Retry 2]
     │             │             │
     │             │             ├──fail──► [Alert]
```

**Configuration:**

```javascript
// In workflow settings
{
  "retryOnFail": {
    "enabled": true,
    "maxTries": 3,
    "waitBetweenTries": 30000, // 30s
    "backoffMultiplier": 2    // 30s → 60s → 120s
  }
}
```

### 4. Graceful Degradation

```javascript
// If API fails, use cached/default data
try {
  const data = await fetchAPI();
  return { json: data };
} catch (error) {
  console.error('API failed, using fallback:', error);
  return {
    json: {
      ...$json,
      data: DEFAULT_VALUES,
      fallback: true,
      error: error.message
    }
  };
}
```

---

## Performance Optimization

### 1. Batch Operations

**❌ Bad - One at a time:**

```
[Loop 1000 items]
  → [HTTP Request] (1000 calls)
```

**✅ Good - Batch:**

```
[Split into chunks of 100]
  → [HTTP Request] (10 calls with 100 items each)
```

**Implementation:**

```javascript
// Chunk array
const chunkSize = 100;
const items = $input.all();
const chunks = [];

for (let i = 0; i < items.length; i += chunkSize) {
  chunks.push(items.slice(i, i + chunkSize));
}

// Return first chunk
return chunks[0];
```

### 2. Pagination Handling

```javascript
// Fetch all pages
async function fetchAllPages(url) {
  let allItems = [];
  let page = 1;
  let hasMore = true;
  
  while (hasMore) {
    const response = await fetch(`${url}?page=${page}&limit=100`);
    const data = await response.json();
    
    allItems = allItems.concat(data.items);
    hasMore = data.has_more;
    page++;
    
    // Rate limiting
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  
  return allItems;
}
```

### 3. Avoid Common Bottlenecks

| Bottleneck | Solution |
|------------|----------|
| **Too many items** | Split into batches |
| **Slow API** | Cache results, use pagination |
| **Large payloads** | Select only needed fields |
| **Sequential processing** | Parallel where possible |
| **No pruning** | Clean old executions |

### 4. Execution Settings

```bash
# Environment variables
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168        # 7 days
EXECUTIONS_DATA_PRUNE_MAX_COUNT=10000

# Queue mode for heavy workloads
EXECUTIONS_MODE=queue
QUEUE_BULL_REDIS_HOST=redis
```

### 5. Memory Management

**For large datasets:**

```javascript
// Process in chunks, don't load all at once
const CHUNK_SIZE = 500;

async function processLargeDataset() {
  let offset = 0;
  
  while (true) {
    const chunk = await fetchChunk(offset, CHUNK_SIZE);
    if (chunk.length === 0) break;
    
    await processChunk(chunk);
    offset += CHUNK_SIZE;
  }
}
```

---

## Security

### 1. Credentials Management

**✅ Do:**
- Store credentials in N8N credential manager
- Use environment variables for sensitive config
- Rotate API keys regularly
- Use OAuth2 when possible

**❌ Don't:**
- Hardcode passwords in workflow
- Commit credentials to git
- Log sensitive data
- Share credentials unnecessarily

### 2. Input Validation

```javascript
// Always validate input
const validateInput = (input) => {
  const errors = [];
  
  if (!input.email || !/\S+@\S+\.\S+/.test(input.email)) {
    errors.push('Invalid email');
  }
  
  if (!input.name || input.name.length < 2) {
    errors.push('Name too short');
  }
  
  if (input.phone && !/^\+?[\d\s-]{10,}$/.test(input.phone)) {
    errors.push('Invalid phone');
  }
  
  if (errors.length > 0) {
    throw new Error(`Validation failed: ${errors.join(', ')}`);
  }
  
  return input;
};
```

### 3. Sanitize Output

```javascript
// Remove sensitive fields before sending
const sanitizeForExternal = (data) => {
  const { password, api_key, internal_id, ...safeData } = data;
  return safeData;
};
```

### 4. Audit Logging

```javascript
// Log important actions
const auditLog = {
  action: 'lead_created',
  user: $json.email,
  timestamp: new Date().toISOString(),
  details: {
    source: $json.source,
    ip: $json.ip_address
  }
};

console.log('AUDIT:', JSON.stringify(auditLog));
```

### 5. Rate Limiting

```javascript
// Implement rate limiting
const RATE_LIMIT = 100; // requests per minute
const WINDOW = 60 * 1000; // 1 minute

let requestCount = 0;
let windowStart = Date.now();

function checkRateLimit() {
  const now = Date.now();
  
  if (now - windowStart > WINDOW) {
    requestCount = 0;
    windowStart = now;
  }
  
  if (requestCount >= RATE_LIMIT) {
    throw new Error('Rate limit exceeded');
  }
  
  requestCount++;
}
```

---

## Maintenance

### 1. Regular Tasks

| Task | Frequency | Action |
|------|-----------|--------|
| **Prune executions** | Weekly | `n8n prune-executions --before 7d` |
| **Review errors** | Daily | Check failed executions |
| **Update credentials** | Monthly | Rotate API keys |
| **Update N8N** | Monthly | Apply security patches |
| **Backup workflows** | Daily | Export or git backup |
| **Review logs** | Weekly | Check for anomalies |

### 2. Workflow Review Checklist

```
□ Workflow has clear, descriptive name
□ All nodes have meaningful names
□ Error handling is in place
□ Credentials are properly managed
□ Logging is appropriate
□ Performance is acceptable
□ Documentation is up to date
□ Tests pass (if applicable)
□ Tags are correct
□ Owner is assigned (Enterprise)
```

### 3. Version Control

**Export workflows regularly:**

```bash
#!/bin/bash
# backup-workflows.sh

BACKUP_DIR="/backup/n8n/workflows"
DATE=$(date +%Y%m%d)

mkdir -p $BACKUP_DIR

# Export via API
curl -s http://localhost:5678/api/v1/workflows \
  -H "X-N8N-API-KEY: $API_KEY" \
  > $BACKUP_DIR/workflows-$DATE.json

# Keep last 30 days
find $BACKUP_DIR -type f -mtime +30 -delete

echo "Backup completed: $DATE"
```

### 4. Monitoring

**Key metrics to track:**

| Metric | Alert Threshold |
|--------|-----------------|
| **Failed executions** | > 5% of total |
| **Avg execution time** | > 30 seconds |
| **Queue depth** | > 1000 items |
| **Memory usage** | > 80% |
| **Disk usage** | > 85% |

---

## Testing

### 1. Manual Testing

**Before activating:**

1. Execute workflow manually
2. Check each node's output
3. Verify error handling works
4. Test with edge cases
5. Review logs

### 2. Test Data

**Use realistic test data:**

```javascript
// Test cases
const testCases = [
  { name: 'Valid lead', data: validLead, expected: 'success' },
  { name: 'Missing email', data: noEmail, expected: 'error' },
  { name: 'Duplicate', data: existingLead, expected: 'update' },
  { name: 'Invalid phone', data: badPhone, expected: 'error' }
];
```

### 3. Integration Testing

```javascript
// Test workflow end-to-end
async function testWorkflow() {
  // Trigger workflow
  const result = await triggerWorkflow(testData);
  
  // Verify CRM creation
  const contact = await getCRMContact(result.email);
  assert(contact.exists);
  
  // Verify notification sent
  const slackMessages = await getSlackMessages();
  assert(slackMessages.length > 0);
  
  console.log('All tests passed!');
}
```

---

## Documentation

### 1. Workflow Documentation Template

```markdown
# Workflow: [Name]

## Purpose
Brief description of what this workflow does

## Trigger
- Type: [Schedule/Webhook/App]
- Frequency: [Daily/Real-time]
- Input: [Expected data format]

## Process
1. Step 1 description
2. Step 2 description
3. Step 3 description

## Output
- What gets created/updated
- Where data goes
- Notifications sent

## Error Handling
- What happens on failure
- Who gets notified
- Recovery process

## Dependencies
- Required credentials
- External services
- Other workflows

## Maintenance
- Owner: [Name/Team]
- Last updated: [Date]
- Known issues: [List]
```

### 2. Node Comments

Add notes to complex nodes:

```
Node: Code - Calculate Lead Score
Note: Uses weighted scoring algorithm. 
      Weights configured in env variables.
      Contact: john.doe@company.com for changes
```

### 3. Changelog

Keep track of changes:

```markdown
## Changelog

### 2024-01-15
- Added lead enrichment with Clearbit
- Improved error handling

### 2024-01-01
- Initial version
- Basic lead creation from forms
```

---

## Common Anti-Patterns

### ❌ 1. God Workflow

One workflow that does everything.

**Problem:** Hard to maintain, debug, and scale.

**Solution:** Split into focused, reusable workflows.

### ❌ 2. No Error Handling

Workflows fail silently.

**Problem:** Issues go unnoticed, data gets lost.

**Solution:** Always add error handling and alerts.

### ❌ 3. Hardcoded Values

Credentials, URLs, configs in workflow.

**Problem:** Hard to maintain, security risk.

**Solution:** Use credentials manager and env variables.

### ❌ 4. No Logging

No visibility into what happened.

**Problem:** Impossible to debug or audit.

**Solution:** Log important actions and outcomes.

### ❌ 5. Skipping Validation

Trust input data blindly.

**Problem:** Bad data propagates, causes errors.

**Solution:** Always validate input data.

### ❌ 6. No Rate Limiting

Hit API limits.

**Problem:** Workflows fail, data sync breaks.

**Solution:** Implement rate limiting and backoff.

### ❌ 7. Ignoring Performance

Slow workflows, high memory.

**Problem:** System becomes unusable.

**Solution:** Batch operations, prune executions, monitor.

---

## 💡 Quick Reference

### Essential Checklist

```
□ Workflow named clearly
□ Nodes have descriptive names
□ Tags applied
□ Error handling configured
□ Credentials secure
□ Input validated
□ Output sanitized
□ Logging appropriate
□ Performance acceptable
□ Documentation complete
□ Backup current version
□ Test before activate
□ Monitor after deploy
```

---

## 🔗 Tài liệu liên quan

- [41. Workflow Patterns](41-workflow-patterns.md)
- [42. Troubleshooting](42-troubleshooting.md)
- [08. Error Handling](08-error-handling-debugging.md)

---

**[← Quay lại mục lục](README.md)**
