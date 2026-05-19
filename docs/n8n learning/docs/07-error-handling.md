# 🛡️ Xử lý lỗi và Debug

## Error Types trong N8N

### 1. Node Errors

```
API Errors:
├── 401 Unauthorized (sai credentials)
├── 403 Forbidden (không có permission)
├── 404 Not Found (resource không tồn tại)
├── 429 Too Many Requests (rate limit)
└── 500+ Server Errors

Data Errors:
├── Missing fields
├── Invalid format
├── Type mismatch
└── Empty responses

Connection Errors:
├── Timeout
├── DNS resolution failed
├── SSL certificate error
└── Network unreachable
```

### 2. Workflow Errors

```
Execution Errors:
├── Syntax error trong Code Node
├── Reference node không tồn tại
├── Circular dependency
└── Memory limit exceeded

Configuration Errors:
├── Missing required fields
├── Invalid webhook URL
├── Credential expired
└── Node version incompatibility
```

---

## 🎯 Error Handling Strategies

### Strategy 1: Node-Level Error Handling

**Node Settings → On Error:**

```
Options:
├── Stop Workflow (default)
│   Dừng ngay khi có lỗi
│
├── Continue Regular Output
│   Bỏ qua lỗi, continue với item tiếp theo
│
└── Continue Error Output
    Gửi lỗi đến error output để xử lý
```

**Ví dụ: Continue Error Output**

```
┌──────────────┐
│  HTTP Request│
│              │
│  [Regular] ──┼──► Process Success
│  [Error]  ───┼──► Handle Error
└──────────────┘
```

### Strategy 2: Error Trigger Workflow

**Workflow riêng để handle errors:**

```
Main Workflow:
  Settings → Error Workflow → [Select Error Handler]

Error Handler Workflow:
  Trigger: Error Trigger
  ├─ Parse error details
  ├─ Log to database
  ├─ Send notification
  └─ Retry if needed
```

### Strategy 3: Try-Catch Pattern

```
┌─────────────┐
│   IF Node   │  Validate trước
│             │
│  [True] ────┼──► Process (try)
│  [False] ───┼──► Handle Error (catch)
└─────────────┘
```

### Strategy 4: Stop And Error Node

**Explicitly fail workflow:**

```javascript
// Code Node validation
const items = $input.all();

for (const item of items) {
  if (!item.json.email) {
    throw new Error('Email is required');
  }
  
  if (item.json.age < 18) {
    throw new Error('Must be 18 or older');
  }
}

return items;
```

---

## 🔄 Retry Logic

### Built-in Retry

**Node Settings:**
```
Retry On Fail: ✅ true
Max Retries: 3
Retry Delay: 5000ms (5 seconds)
```

### Custom Retry Pattern

```javascript
let retries = 0;
const maxRetries = 3;
let success = false;
let result;

while (retries < maxRetries && !success) {
  try {
    const response = await fetch('https://api.example.com/data');
    
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    
    result = await response.json();
    success = true;
  } catch (error) {
    retries++;
    console.log(`Retry ${retries}/${maxRetries}`);
    
    if (retries === maxRetries) {
      throw new Error(`Failed after ${maxRetries} retries: ${error.message}`);
    }
    
    await new Promise(resolve => setTimeout(resolve, 2000 * retries));
  }
}

return [{ json: { data: result, retries } }];
```

---

## 🐛 Debugging Techniques

### 1. Pin Data

**Pin data để test không cần trigger:**

1. Chạy workflow
2. Click node output
3. Click **"Pin"** icon
4. Data được lưu cho lần test sau

### 2. Partial Execution

**Execute từ node cụ thể:**

1. Right-click node
2. **"Execute from here"**
3. Workflow chạy từ node đó trở đi

### 3. Console Logging

```javascript
// Log input
console.log('Input count:', $input.all().length);

// Log specific items
console.log('First item:', JSON.stringify($input.first().json, null, 2));

// Performance timing
const start = Date.now();
// ... processing ...
console.log('Processing time:', Date.now() - start, 'ms');
```

### 4. Execution History

**View past executions:**

1. Workflow → Executions tab
2. Click execution
3. View:
   - Status (success/error/waiting)
   - Duration
   - Node-by-node execution
   - Input/output data

---

## 🚨 Common Errors & Solutions

### 1. "Node not found" Error

**Solution:**
```javascript
// ✅ Safe reference
{{ $node["Existing Node"] ? $node["Existing Node"].json.id : null }}
```

### 2. "Cannot read property of undefined"

**Solution:**
```javascript
// ✅ Optional chaining
{{ $json.user?.profile?.avatar ?? 'default.png' }}
```

### 3. "Rate limit exceeded"

**Solution:**
```
Add Wait Node between requests:
  Duration: 1-2 seconds

Hoặc Loop với batch size nhỏ:
  Batch size: 10 items
  Wait: 1 second between batches
```

### 4. "Execution timeout"

**Solution:**
```bash
# Tăng timeout
N8N_EXECUTIONS_TIMEOUT=-1  # No timeout
N8N_EXECUTIONS_TIMEOUT_MAX=3600  # 1 hour
```

---

## ✅ Error Handling Checklist

- [ ] Set "On Error" cho nodes quan trọng
- [ ] Create Error Trigger workflow
- [ ] Add validation trước processing
- [ ] Implement retry cho external APIs
- [ ] Log errors đến database/monitoring
- [ ] Setup notifications (Slack/Email)
- [ ] Test error scenarios
- [ ] Document error recovery procedures

---

## 🚀 Next Steps

→ [Webhooks & API](08-webhooks-api.md)
→ [Credentials](09-credentials.md)
