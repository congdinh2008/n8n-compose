# 41. Workflow Patterns - Design Patterns phổ biến

## 📋 Mục lục
- [Cơ bản Patterns](#cơ-bản-patterns)
- [Nâng cao Patterns](#nâng-cao-patterns)
- [Error Handling Patterns](#error-handling-patterns)
- [Data Processing Patterns](#data-processing-patterns)
- [Integration Patterns](#integration-patterns)
- [Anti-Patterns](#anti-patterns)

---

## Cơ bản Patterns

### 1. Sequential Pattern

Chạy các bước tuần tự.

```
[A] → [B] → [C] → [D]
```

**Use case:** Simple data pipeline
**When to use:** Steps depend on previous output

### 2. Conditional Branching

Rẽ nhánh theo điều kiện.

```
         [If Condition?]
        /              \
      Yes              No
       |                |
       v                v
    [Path A]         [Path B]
```

**Implementation:**
```javascript
// If Node condition
{{ $json.status === 'active' }}
```

### 3. Fan-Out Pattern

Một input → Nhiều outputs song song.

```
          [Source]
         /    |    \
        ↓     ↓     ↓
      [A]    [B]    [C]
```

**Use case:** 
- Notify multiple systems
- Parallel API calls
- Send to multiple channels

### 4. Fan-In Pattern

Nhiều inputs → Một output.

```
    [A]    [B]    [C]
     \      |     /
      \     |    /
       [Merge]
          ↓
      [Process]
```

**Use case:**
- Aggregate data from sources
- Combine results
- Unified processing

---

## Nâng cao Patterns

### 5. Circuit Breaker Pattern

Prevent cascading failures.

```
[Task] → [Success?]
           ↓    ↓
         Yes    No (3x)
          |      |
          v      v
     [Continue] [Stop + Alert]
```

**Implementation:**

```javascript
// Track consecutive failures
const consecutiveFailures = $('Counter').item.json.count || 0;

if (consecutiveFailures >= 3) {
  throw new Error('Circuit breaker: Too many failures, stopping');
}

// Continue with task
const result = await doTask();

if (result.success) {
  return { json: { count: 0, ...result } };
} else {
  return { json: { count: consecutiveFailures + 1 } };
}
```

### 6. Retry with Backoff Pattern

Exponential backoff cho retries.

```
[Task] → Fail → Wait 30s → Retry
              ↓ Fail
         Wait 2m → Retry
              ↓ Fail
         Wait 10m → Retry
              ↓ Fail
         Alert + Stop
```

**Implementation:**

```javascript
const attempt = $json.attempt || 1;
const maxAttempts = 5;

if (attempt > maxAttempts) {
  throw new Error(`Max attempts (${maxAttempts}) reached`);
}

const waitTime = Math.min(30000 * Math.pow(2, attempt - 1), 600000);

return {
  json: {
    ...$json,
    attempt: attempt + 1,
    wait_time: waitTime,
    next_retry: new Date(Date.now() + waitTime).toISOString()
  }
};
```

### 7. Batch Processing Pattern

Xử lý dữ liệu theo batches.

```
[1000 Items]
     ↓
[Split into chunks of 100]
     ↓
[Process Batch 1] → [Process Batch 2] → ...
     ↓
[Aggregate Results]
```

**Implementation:**

```javascript
const items = $input.all();
const batchSize = 100;
const batches = [];

for (let i = 0; i < items.length; i += batchSize) {
  batches.push({
    json: {
      batch: items.slice(i, i + batchSize),
      batch_number: Math.floor(i / batchSize) + 1,
      total_batches: Math.ceil(items.length / batchSize)
    }
  });
}

return batches;
```

### 8. State Machine Pattern

Quản lý states phức tạp.

```
[New] → [Processing] → [Complete]
  ↓          ↓
[Error]  [Retry]
```

**Implementation:**

```javascript
const validTransitions = {
  'new': ['processing', 'error'],
  'processing': ['complete', 'retry', 'error'],
  'retry': ['processing', 'error'],
  'complete': [],
  'error': ['new']
};

const currentState = $json.state;
const nextState = $json.next_state;

if (!validTransitions[currentState].includes(nextState)) {
  throw new Error(
    `Invalid transition: ${currentState} → ${nextState}`
  );
}

return { json: { ...$json, state: nextState } };
```

---

## Error Handling Patterns

### 9. Try-Catch Pattern

```
[Try Block]
    |
    ├── Success → [Continue]
    |
    └── Fail → [Catch Block]
                    |
                    ├── [Log Error]
                    ├── [Notify]
                    └── [Recovery Action]
```

**Implementation:**

```javascript
try {
  const result = await riskyOperation();
  return { json: { success: true, data: result } };
} catch (error) {
  return {
    json: {
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    }
  };
}
```

### 10. Graceful Degradation Pattern

Fallback khi service unavailable.

```
[Primary API] → Fail → [Fallback Source] → Fail → [Default Values]
```

**Implementation:**

```javascript
let data;

try {
  data = await fetchPrimaryAPI();
} catch (error) {
  console.warn('Primary API failed, trying fallback');
  try {
    data = await fetchFallbackAPI();
  } catch (fallbackError) {
    console.error('Both sources failed, using defaults');
    data = DEFAULT_VALUES;
  }
}

return { json: data };
```

### 11. Dead Letter Queue Pattern

Failed items → Queue for later processing.

```
[Process] → Fail → [DLQ]
                       ↓
              [Store for Review]
                       ↓
              [Manual/Scheduled Retry]
```

**Implementation:**

```javascript
// In error handler
const failedItem = {
  original_data: $json,
  error: $input.first().error?.message,
  workflow: $workflow.name,
  timestamp: new Date().toISOString(),
  retry_count: ($json.retry_count || 0) + 1
};

// Save to database for DLQ
await $('Database').execute('insert', {
  table: 'dead_letter_queue',
  data: failedItem
});

return { json: failedItem };
```

---

## Data Processing Patterns

### 12. Enrichment Pattern

Bổ sung data từ external sources.

```
[Base Data] → [Enrich Source 1] → [Enrich Source 2] → [Enriched Data]
```

**Implementation:**

```javascript
const baseData = $json;

// Parallel enrichment
const [geoData, companyData] = await Promise.all([
  fetchGeoData(baseData.ip),
  fetchCompanyData(baseData.email)
]);

return {
  json: {
    ...baseData,
    country: geoData.country,
    company: companyData.name,
    company_size: companyData.size,
    enriched_at: new Date().toISOString()
  }
};
```

### 13. Deduplication Pattern

Loại bỏ duplicates.

```
[Items] → [Check Unique] → [Unique Items]
                ↓
           [Duplicate] → [Merge/Ignore]
```

**Implementation:**

```javascript
const items = $input.all();
const seen = new Set();

const unique = items.filter(item => {
  const key = `${item.json.email}_${item.json.company}`;
  if (seen.has(key)) {
    return false; // Duplicate
  }
  seen.add(key);
  return true;
});

return unique;
```

### 14. Aggregation Pattern

Tổng hợp dữ liệu.

```
[Multiple Items] → [Aggregate] → [Summary]
```

**Implementation:**

```javascript
const items = $input.all();

const summary = items.reduce((acc, item) => {
  const category = item.json.category;
  
  if (!acc[category]) {
    acc[category] = { count: 0, total: 0 };
  }
  
  acc[category].count++;
  acc[category].total += item.json.value;
  
  return acc;
}, {});

return { json: { summary, total_items: items.length } };
```

---

## Integration Patterns

### 15. Webhook to Queue Pattern

Async processing.

```
[Webhook] → [Validate] → [Queue] → [Process Later]
```

**Use case:** High volume, non-urgent tasks

### 16. Polling Pattern

Check for changes periodically.

```
[Schedule] → [Fetch Data] → [Compare] → [Changed?] → [Process]
                                                        ↓
                                               [Store New State]
```

**Implementation:**

```javascript
// Fetch current state
const currentData = await fetchData();

// Fetch last known state
const lastState = $('Database').item.json;

// Compare
const changes = currentData.filter(item => 
  item.updated_at > lastState.last_check
);

if (changes.length > 0) {
  return { json: { changes, count: changes.length } };
}

return { json: { changes: [], count: 0 } };
```

### 17. Sync Pattern (Bidirectional)

Đồng bộ 2 chiều.

```
[System A] ←→ [Compare & Merge] ←→ [System B]
```

**Implementation:**

```javascript
// Fetch from both systems
const systemA = await fetchFromSystemA();
const systemB = await fetchFromSystemB();

// Find differences
const diffs = compare(systemA, systemB);

// Resolve conflicts
const resolved = resolveConflicts(diffs, {
  strategy: 'last_write_wins' // or custom logic
});

// Apply updates
await applyUpdates(resolved);
```

---

## Anti-Patterns

### ❌ 1. Spaghetti Workflow

Quá nhiều nhánh rối rắm.

```
[A] → [B] → [C] → [D]
      ↓     ↑     ↓
      [E] → [F] → [G]
            ↓     ↑
            [H] ← [I]
```

**Problem:** Impossible to understand and maintain
**Solution:** Split into multiple workflows

### ❌ 2. God Node

Một node làm quá nhiều việc.

```javascript
// ❌ Bad - Too many responsibilities
const result = (() => {
  // Validate
  // Enrich
  // Transform
  // Call 3 APIs
  // Update database
  // Send emails
  // Generate report
  // 500 lines of code
})();

// ✅ Good - Separate concerns
const validated = validate(input);
const enriched = await enrich(validated);
const transformed = transform(enriched);
await save(transformed);
await notify(transformed);
```

### ❌ 3. No Error Handling

```
[A] → [B] → [C]
```

**Problem:** One failure breaks everything
**Solution:** Add error handling

### ❌ 4. Hardcoded Everything

```javascript
// ❌ Bad
const API_URL = 'https://api.example.com/v1/users';
const TIMEOUT = 5000;
const RETRY = 3;

// ✅ Good
const API_URL = $env.API_URL;
const TIMEOUT = parseInt($env.API_TIMEOUT) || 5000;
const RETRY = parseInt($env.API_RETRY) || 3;
```

### ❌ 5. Ignoring Rate Limits

```javascript
// ❌ Bad - Hit API 1000 times in loop
items.forEach(item => {
  fetch(`https://api.example.com/update/${item.id}`);
});

// ✅ Good - Batch and rate limit
const batches = chunk(items, 100);
for (const batch of batches) {
  await fetch('https://api.example.com/batch-update', {
    method: 'POST',
    body: JSON.stringify({ items: batch })
  });
  await sleep(1000); // Rate limit
}
```

---

## Pattern Selection Guide

| Scenario | Recommended Pattern |
|----------|-------------------|
| Simple pipeline | Sequential |
| Different paths | Conditional Branching |
| Multiple outputs | Fan-Out |
| Combine data | Fan-In |
| Unreliable API | Circuit Breaker + Retry |
| Large dataset | Batch Processing |
| Complex states | State Machine |
| External enrichment | Enrichment Pattern |
| Remove duplicates | Deduplication |
| Summary stats | Aggregation |

---

## 💡 Tips

### When to Use Which Pattern

1. **Start simple**: Sequential first
2. **Add complexity only when needed**
3. **Always handle errors**: Try-Catch minimum
4. **Think about scale**: Will this work with 1000x data?
5. **Document choices**: Why this pattern?

### Pattern Composition

Patterns can be combined:

```
[Fan-Out] + [Circuit Breaker] + [Retry]
= Parallel API calls with failure protection
```

---

**[← Quay lại: 40. Best Practices](40-best-practices.md)** | **[Tiếp theo: 42. Troubleshooting →](42-troubleshooting.md)**
