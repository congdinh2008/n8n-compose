# Best Practices - Workflow Design Patterns

## 1. Design Patterns

### Pattern 1: Sequential Processing
```
Trigger → Transform → Output
```

**Use case:** Simple data transformations

**Example:**
```
Webhook → Format data → Save to DB
```

### Pattern 2: Conditional Branching
```
Trigger → Validate → [Valid] → Process
                      └→ [Invalid] → Error handling
```

**Use case:** Data validation, routing

### Pattern 3: Fan-out/Fan-in
```
Trigger → Process A ──┐
                      └→ Aggregate → Output
Trigger → Process B ──┘
```

**Use case:** Parallel processing

### Pattern 4: Loop with Aggregation
```
Trigger → Split → Process Each → Aggregate → Single Output
```

**Use case:** Batch processing

### Pattern 5: Retry Pattern
```
Process → [Success] → Continue
     ↓
    Error → Wait → Retry → [Max retries] → Fail
```

---

## 2. Naming Conventions

### Workflow Names
```
✅ Good:
- Daily CRM Sync
- Lead Capture from Website
- Weekly Sales Report
- Invoice Processing

❌ Bad:
- Workflow 1
- Test
- New Workflow
- Untitled
```

### Node Names
```
✅ Good:
- Get Users from DB
- Validate Email format
- Send Slack notification
- Calculate total revenue

❌ Bad:
- PostgreSQL
- Code
- Slack
- HTTP Request
```

---

## 3. Workflow Organization

### Layout Best Practices
```
┌─────────────────────────────────────────────┐
│                                             │
│  [Trigger] → [Validate] → [Process]        │
│                                │            │
│                           [IF Error]        │
│                                │            │
│                      ┌─────────┴────────┐   │
│                      ↓                  ↓   │
│                 [Handle]           [Notify]  │
│                                             │
│  [Comments explaining complex sections]     │
│                                             │
└─────────────────────────────────────────────┘
```

### Tips
- Left to right flow
- Group related nodes
- Use Comments node for explanations
- Color-code by function
- Keep workflows < 50 nodes (split if larger)

---

## 4. Performance Optimization

### Batch Processing
```javascript
// ❌ Slow - One item at a time
items.forEach(item => {
  await saveToDatabase(item);
});

// ✅ Fast - Batch operation
await saveToDatabaseBatch(items);
```

### Pagination
```javascript
// Handle large datasets
let page = 1;
let allData = [];

while (true) {
  const response = await fetchAPI({ page, limit: 100 });
  allData = allData.concat(response.data);
  
  if (!response.has_more) break;
  page++;
}
```

### Memory Management
```javascript
// Process in chunks
const CHUNK_SIZE = 100;
const items = $input.all();

for (let i = 0; i < items.length; i += CHUNK_SIZE) {
  const chunk = items.slice(i, i + CHUNK_SIZE);
  await processChunk(chunk);
}
```

---

## 5. Error Handling Best Practices

### Always Implement
```
Every workflow should have:
✅ Validation nodes
✅ Error handling
✅ Logging
✅ Notifications for critical failures
```

### Error Context
```javascript
// Include context in errors
try {
  const result = await process(data);
} catch (error) {
  console.error(JSON.stringify({
    error: error.message,
    workflow: $workflow.name,
    node: $node.name,
    data_summary: {
      id: data.id,
      type: data.type
    }
  }));
  throw error;
}
```

---

## 6. Security Best Practices

### Credentials
```
✅ Store in n8n credentials manager
✅ Use environment variables
✅ Rotate regularly
✅ Never hardcode in workflows

❌ Don't commit credentials to git
❌ Don't share in plain text
```

### Data Protection
```
✅ Encrypt sensitive data
✅ Mask PII in logs
✅ Use HTTPS for webhooks
✅ Implement rate limiting

❌ Don't log passwords
❌ Don't expose tokens in URLs
❌ Don't store unnecessary PII
```

### Webhook Security
```javascript
// Verify signatures
const crypto = require('crypto');
const signature = headers['x-hub-signature-256'];
const expected = 'sha256=' + crypto
  .createHmac('sha256', secret)
  .update(payload)
  .digest('hex');

if (signature !== expected) {
  throw new Error('Invalid webhook signature');
}
```

---

## 7. Testing Strategy

### Unit Testing
```
Test each node independently:
1. Pin input data
2. Execute node
3. Verify output
4. Test edge cases
```

### Integration Testing
```
Test full workflow:
1. Use realistic test data
2. Trigger workflow
3. Verify end state
4. Check all integrations
```

### Load Testing
```bash
# Simulate production load
for i in {1..100}; do
  curl -X POST https://n8n.domain.com/webhook/test \
    -d "{\"id\": $i}" &
done
wait
```

---

## 8. Version Control

### Export Workflows
```bash
# Regular exports
n8n export:workflow --id=123 --output=workflows/crm-sync.json

# Commit to git
git add workflows/
git commit -m "Update CRM sync workflow - add error handling"
```

### Change Documentation
```markdown
## Changes Made
- Added email validation
- Implemented retry logic
- Updated error notifications
- Fixed duplicate handling

## Testing Done
- ✅ Test with valid emails
- ✅ Test with invalid emails
- ✅ Test retry logic
- ✅ Test error notifications
```

---

## 9. Monitoring Best Practices

### Key Metrics
```
✅ Execution count
✅ Success rate
✅ Average duration
✅ Error rate
✅ Queue size (if applicable)
```

### Alerts
```
Set alerts for:
- Error rate > 5%
- Execution time > threshold
- Queue backlog > 100
- Memory usage > 80%
```

### Logging
```javascript
// Structured logging
console.log(JSON.stringify({
  level: 'info',
  workflow: $workflow.name,
  timestamp: new Date().toISOString(),
  data: {
    items_processed: $input.all().length
  }
}));
```

---

## 10. Scaling Considerations

### When to Scale
```
Scale when:
- Executions > 10,000/day
- Queue growing constantly
- Memory usage high
- Response times slow
```

### Scaling Options
```
1. Vertical scaling (bigger server)
2. Horizontal scaling (more workers)
3. Queue mode with Redis
4. External database
5. Load balancer
```

### Queue Mode Setup
```yaml
# docker-compose.yml
services:
  n8n-main:
    environment:
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
  
  n8n-worker:
    command: worker
    # Can have multiple workers
    deploy:
      replicas: 3
```

---

## 11. Common Pitfalls

### ❌ Anti-patterns to Avoid

**1. Monolithic workflows**
```
One huge workflow doing everything
→ Split into smaller workflows
```

**2. No error handling**
```
Assuming everything will work
→ Always handle failures
```

**3. Hardcoded values**
```
API keys, URLs, limits in workflow
→ Use variables/credentials
```

**4. Infinite loops**
```
Recursive workflows without exit
→ Always have max iteration limit
```

**5. Ignoring rate limits**
```
Calling APIs without respecting limits
→ Implement rate limit handling
```

---

## 12. Checklist Before Production

### Pre-deployment Checklist
```
Workflow Design:
☐ Workflow has clear name
☐ All nodes have descriptive names
☐ Error handling implemented
☐ Logging configured
☐ Comments for complex logic

Testing:
☐ Tested with valid data
☐ Tested with invalid data
☐ Tested error scenarios
☐ Load tested

Security:
☐ No hardcoded credentials
☐ Webhooks secured
☐ Sensitive data protected
☐ Rate limits respected

Monitoring:
☐ Alerts configured
☐ Metrics enabled
☐ Logging setup
☐ Error notifications

Operations:
☐ Backup configured
☐ Rollback plan ready
☐ Documentation updated
☐ Team trained
```
