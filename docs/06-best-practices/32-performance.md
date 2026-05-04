# Performance Optimization

## 1. Execution Performance

### Factors Affecting Performance

| Factor | Impact | Solution |
|--------|--------|----------|
| **Item count** | High | Process in batches |
| **Binary data size** | High | Use filesystem mode |
| **External API calls** | High | Cache responses |
| **Complex expressions** | Medium | Use Code node |
| **Memory usage** | High | Increase heap size |
| **Database queries** | Medium | Optimize queries |

---

## 2. Memory Management

### Node.js Heap Size

**Default limits:**
```
Node.js 14: ~1.4GB
Node.js 16+: ~2GB
```

**Increase heap size:**
```bash
NODE_OPTIONS=--max-old-space-size=4096
```

### Memory Monitoring

**Check memory usage:**
```javascript
// Code node
const memory = process.memoryUsage();
return [{
  json: {
    rss: (memory.rss / 1024 / 1024).toFixed(2) + ' MB',
    heapTotal: (memory.heapTotal / 1024 / 1024).toFixed(2) + ' MB',
    heapUsed: (memory.heapUsed / 1024 / 1024).toFixed(2) + ' MB',
    external: (memory.external / 1024 / 1024).toFixed(2) + ' MB'
  }
}];
```

### Binary Data Mode

**For large files:**
```bash
N8N_DEFAULT_BINARY_DATA_MODE=filesystem
N8N_BINARY_DATA_PATH=/tmp/n8n-binary
```

---

## 3. Batch Processing

### Why Batch?

**Problem:**
```
10,000 items → Process all → Memory error
```

**Solution:**
```
10,000 items → 100 batches → Process each → Success
```

### Batch Implementation

**Split into batches:**
```javascript
const items = $input.all();
const BATCH_SIZE = 100;
const batches = [];

for (let i = 0; i < items.length; i += BATCH_SIZE) {
  batches.push(items.slice(i, i + BATCH_SIZE));
}

// Return first batch
return batches[0];
```

**Process batches with Loop:**
```
Schedule → Get Items → Split Batches → Process Batch → 
Update Progress → More Batches? → Yes: Loop / No: Done
```

### Database Batch Operations

**Batch insert:**
```javascript
const items = $input.all();
const BATCH_SIZE = 500;

// Split into batches
const batches = [];
for (let i = 0; i < items.length; i += BATCH_SIZE) {
  batches.push(items.slice(i, i + BATCH_SIZE));
}

// Return for processing
return batches.map((batch, index) => ({
  json: {
    batch_index: index,
    total_batches: batches.length,
    items: batch.map(item => item.json),
    is_last: index === batches.length - 1
  }
}));
```

---

## 4. API Rate Limiting

### Respect Rate Limits

**Common limits:**
| Service | Limit |
|---------|-------|
| Twitter | 300 req/15min |
| GitHub | 5000 req/hour |
| Slack | 1 req/sec |
| HubSpot | 250 req/10sec |

### Rate Limit Handling

**Implementation:**
```javascript
const response = await fetch(url);

if (response.status === 429) {
  const retryAfter = response.headers.get('Retry-After') || 60;
  console.log(`Rate limited. Waiting ${retryAfter} seconds`);
  await new Promise(r => setTimeout(r, retryAfter * 1000));
  // Retry request
}

// Check remaining limit
const remaining = response.headers.get('x-ratelimit-remaining');
const reset = response.headers.get('x-ratelimit-reset');

if (remaining === '0') {
  const waitTime = (reset * 1000) - Date.now();
  await new Promise(r => setTimeout(r, waitTime));
}
```

### Throttling

**Simple throttler:**
```javascript
const requests = [];
const MAX_PER_SECOND = 10;

async function throttledFetch(url, options) {
  const now = Date.now();
  
  // Remove old requests
  while (requests.length > 0 && requests[0] < now - 1000) {
    requests.shift();
  }
  
  // Wait if at limit
  if (requests.length >= MAX_PER_SECOND) {
    const waitTime = 1000 - (now - requests[0]);
    await new Promise(r => setTimeout(r, waitTime));
  }
  
  requests.push(Date.now());
  return fetch(url, options);
}
```

---

## 5. Query Optimization

### Database Queries

**❌ Slow:**
```sql
SELECT * FROM users
```

**✅ Fast:**
```sql
SELECT id, name, email FROM users 
WHERE created_at > NOW() - INTERVAL '24 hours'
LIMIT 1000
```

### Pagination

**Offset-based:**
```javascript
let page = 1;
let allData = [];

while (true) {
  const response = await fetchAPI({
    page,
    limit: 100
  });
  
  allData = allData.concat(response.data);
  
  if (response.data.length < 100) break;
  page++;
}
```

**Cursor-based (better):**
```javascript
let cursor = null;
let allData = [];

while (true) {
  const response = await fetchAPI({
    cursor,
    limit: 100
  });
  
  allData = allData.concat(response.data);
  cursor = response.next_cursor;
  
  if (!cursor) break;
}
```

---

## 6. Caching

### Cache API Responses

**Simple cache:**
```javascript
const cache = {};

async function getCachedData(key, fetchFn, ttl = 300000) {
  const cached = cache[key];
  
  if (cached && Date.now() - cached.timestamp < ttl) {
    return cached.data;
  }
  
  const data = await fetchFn();
  cache[key] = { data, timestamp: Date.now() };
  return data;
}
```

### Redis Cache

**With Redis:**
```javascript
const Redis = require('ioredis');
const redis = new Redis();

async function getWithCache(key, fetchFn, ttl = 300) {
  const cached = await redis.get(key);
  
  if (cached) {
    return JSON.parse(cached);
  }
  
  const data = await fetchFn();
  await redis.setex(key, ttl, JSON.stringify(data));
  return data;
}
```

---

## 7. Workflow Optimization

### Reduce Node Count

**❌ Inefficient:**
```
Code → IF → HTTP → Code → IF → HTTP → Code
```

**✅ Efficient:**
```
Code (all logic) → HTTP (batch request)
```

### Parallel Processing

**Run in parallel:**
```
Trigger → Split → Process A ──┐
                              └→ Merge → Output
          → Process B ──┘
```

### Avoid Redundant Operations

**❌ Redundant:**
```javascript
// Called for every item
function getConfig() {
  return { api_key: 'xxx', base_url: 'yyy' };
}

items.map(item => {
  const config = getConfig(); // Called N times
  // process
});
```

**✅ Optimized:**
```javascript
const config = getConfig(); // Called once

items.map(item => {
  // process with config
});
```

---

## 8. Queue Mode Performance

### When to Use Queue Mode

**Use queue mode when:**
- Executions > 100/hour
- Long-running workflows
- Need horizontal scaling
- Require reliability

### Setup Queue Mode

```yaml
# docker-compose.yml
services:
  n8n-main:
    environment:
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
  
  n8n-worker:
    command: worker
    environment:
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
    deploy:
      replicas: 3
```

### Worker Configuration

**Environment variables:**
```bash
# Worker settings
WORKER_TIMEOUT=300
QUEUE_RECOVERY_INTERVAL=60
QUEUE_RECOVERY_BULK_SIZE=100
```

---

## 9. Monitoring Performance

### Key Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Execution time | < 30s | > 5 min |
| Memory usage | < 500MB | > 1GB |
| Queue size | < 50 | > 100 |
| Error rate | < 1% | > 5% |
| API response | < 1s | > 3s |

### Prometheus Metrics

**Enable metrics:**
```bash
N8N_METRICS=true
N8N_METRICS_PREFIX=n8n_
```

**Key metrics:**
```
n8n_workflow_executions_total
n8n_workflow_errors_total
n8n_node_execution_duration_seconds
n8n_queue_size
n8n_memory_usage_bytes
```

### Logging Optimization

**Structured logging:**
```javascript
console.log(JSON.stringify({
  level: 'info',
  workflow: $workflow.name,
  node: $node.name,
  duration_ms: Date.now() - startTime,
  items_processed: $input.all().length,
  memory_mb: process.memoryUsage().heapUsed / 1024 / 1024
}));
```

---

## 10. Troubleshooting Performance

### Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| Memory leak | Increasing memory | Increase heap, check loops |
| Slow execution | Long duration | Optimize queries, batch |
| Queue growing | Backed up | Add workers |
| Rate limited | 429 errors | Add throttling |
| Timeout | Execution fails | Optimize, split workflow |

### Debug Steps

```
1. Check execution logs
2. Monitor memory usage
3. Profile slow nodes
4. Check API response times
5. Review database queries
6. Check queue status
```

### Performance Checklist

- [ ] Use batch processing for large datasets
- [ ] Optimize database queries
- [ ] Implement rate limiting
- [ ] Use filesystem mode for large files
- [ ] Increase Node.js heap if needed
- [ ] Enable queue mode for scale
- [ ] Monitor key metrics
- [ ] Cache API responses
- [ ] Avoid redundant operations
- [ ] Split large workflows
