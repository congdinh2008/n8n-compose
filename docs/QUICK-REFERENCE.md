# N8N Quick Reference Guide

## 📋 Table of Contents
- [Installation](#installation)
- [Common Workflows](#common-workflows)
- [Expressions Cheat Sheet](#expressions-cheat-sheet)
- [Node Configurations](#node-configurations)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Installation

### Docker Compose (Quick Start)
```bash
docker-compose up -d
```

### Production Setup
```yaml
version: '3.8'
services:
  n8n:
    image: n8nio/n8n:latest
    environment:
      - DB_TYPE=postgresdb
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
```

### Environment Variables
```bash
# Required
N8N_ENCRYPTION_KEY=your_32_character_encryption_key
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.yourdomain.com/

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}

# Production
N8N_SAVE_DATA_EXECUTIONS=true
N8N_DIAGNOSTICS_ENABLED=false
N8N_METRICS=true
```

---

## Common Workflows

### 1. Webhook → Process → Email
```json
{
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "httpMethod": "POST",
        "path": "form-submit"
      }
    },
    {
      "name": "Send Email",
      "type": "n8n-nodes-base.emailSend",
      "parameters": {
        "toEmail": "={{ $json.email }}",
        "subject": "New submission from {{ $json.name }}",
        "message": "={{ $json.message }}"
      }
    }
  ]
}
```

### 2. Schedule → API → Database
```json
{
  "nodes": [
    {
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "parameters": {
        "rule": {
          "interval": [{ "field": "hours", "triggerAtMinute": 0 }]
        }
      }
    },
    {
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://api.example.com/data",
        "authentication": "bearerToken"
      }
    },
    {
      "name": "PostgreSQL",
      "type": "n8n-nodes-base.postgres",
      "parameters": {
        "operation": "insert",
        "table": "api_data"
      }
    }
  ]
}
```

### 3. CRM Sync Pattern
```
Webhook → Validate → Check Duplicate → Create/Update → Notify
```

---

## Expressions Cheat Sheet

### Data Access
```javascript
// From previous node
{{ $json.field_name }}
{{ $json.nested.object.value }}

// From specific node
{{ $('Node Name').first().json.field }}
{{ $('Node Name').all() }}

// First/Last/All
{{ $input.first().json.name }}
{{ $input.last().json.name }}
{{ $input.all().length }}
```

### Date/Time
```javascript
// Current time
{{ $now }}
{{ $now.format('yyyy-MM-dd') }}
{{ $now.format('HH:mm:ss') }}
{{ $now.toISO() }}

// Parse date
{{ DateTime.fromISO($json.date) }}
{{ DateTime.fromISO($json.date).toFormat('dd/MM/yyyy') }}

// Add/Subtract
{{ $now.plus({ days: 7 }) }}
{{ $now.minus({ hours: 24 }) }}

// Difference
{{ $now.diff(DateTime.fromISO($json.date), 'days').days }}
```

### String Operations
```javascript
// Transform
{{ $json.text.toUpperCase() }}
{{ $json.text.toLowerCase() }}
{{ $json.text.replace('old', 'new') }}

// Split/Join
{{ $json.tags.split(',').join(' | ') }}

// Concat
{{ 'Hello ' + $json.name }}
{{ $json.first + ' ' + $json.last }}
```

### Number Operations
```javascript
// Math
{{ $json.price * $json.quantity }}
{{ Math.round($json.value) }}
{{ $json.value.toFixed(2) }}

// Aggregate
{{ $input.all().reduce((sum, item) => sum + item.json.amount, 0) }}
{{ Math.max(...$input.all().map(i => i.json.value)) }}
```

### Array Operations
```javascript
// Map
{{ $input.all().map(item => item.json.name) }}

// Filter
{{ $input.all().filter(item => item.json.status === 'active') }}

// Find
{{ $input.all().find(item => item.json.id === 123) }}

// Join
{{ $input.all().map(i => i.json.name).join(', ') }}
```

### Conditional Logic
```javascript
// Ternary
{{ $json.status === 'active' ? '✅' : '❌' }}

// Multiple conditions
{{ $json.score >= 90 ? 'A' : $json.score >= 80 ? 'B' : 'C' }}

// Logical operators
{{ $json.age >= 18 && $json.verified }}
{{ $json.status === 'active' || $json.status === 'pending' }}
```

### Object Operations
```javascript
// Create object
{{ { name: $json.name, email: $json.email } }}

// Spread
{{ { ...$json, processed: true } }}

// Safe access
{{ $json.user?.address?.city ?? 'Unknown' }}
```

---

## Node Configurations

### Webhook Node
```json
{
  "httpMethod": "POST",
  "path": "my-webhook",
  "responseMode": "lastNode",
  "authentication": "headerAuth"
}
```

### HTTP Request Node
```json
{
  "authentication": "bearerToken",
  "requestMethod": "GET",
  "url": "https://api.example.com/endpoint",
  "sendHeaders": true,
  "headerParameters": {
    "parameters": [
      { "name": "Authorization", "value": "Bearer {{ $json.token }}" }
    ]
  },
  "options": {
    "timeout": 30000
  }
}
```

### Code Node (JavaScript)
```javascript
// Input
const items = $input.all();

// Process
const results = items.map(item => ({
  json: {
    ...item.json,
    processed: true,
    timestamp: new Date().toISOString()
  }
}));

// Output
return results;
```

### IF Node
```json
{
  "conditions": {
    "string": [
      {
        "value1": "={{ $json.status }}",
        "operation": "equal",
        "value2": "active"
      }
    ]
  }
}
```

### Schedule Node
```json
{
  "rule": {
    "interval": [
      {
        "field": "days",
        "triggerAtHour": 9,
        "triggerAtMinute": 0
      }
    ]
  }
}
```

---

## Troubleshooting

### Common Errors

| Error | Solution |
|-------|----------|
| `EADDRINUSE` | Change port or kill process |
| `ECONNREFUSED` | Check database is running |
| `401 Unauthorized` | Update credentials |
| `429 Too Many Requests` | Add rate limiting |
| `heap out of memory` | Increase NODE_OPTIONS |

### Debug Commands
```bash
# View logs
docker-compose logs -f n8n

# Check status
docker-compose ps

# Health check
curl http://localhost:5678/healthz

# Test webhook
curl -X POST https://n8n.domain.com/webhook/test \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

### Debug Expressions
```javascript
// Print full input
{{ JSON.stringify($input.all(), null, 2) }}

// Check keys
{{ Object.keys($input.first().json) }}

// Check type
{{ typeof $json.value }}
```

---

## Best Practices

### Workflow Design
- ✅ Descriptive names for workflows and nodes
- ✅ Left-to-right flow
- ✅ Error handling on all critical nodes
- ✅ Comments for complex logic
- ✅ Keep workflows < 50 nodes

### Performance
- ✅ Batch process large datasets
- ✅ Use filesystem mode for binary data
- ✅ Implement rate limiting
- ✅ Cache API responses
- ✅ Use queue mode for scaling

### Security
- ✅ Use credential manager
- ✅ Rotate credentials regularly
- ✅ Verify webhook signatures
- ✅ Use HTTPS everywhere
- ✅ Enable secure cookies

### Data Handling
- ✅ Validate all input
- ✅ Handle missing fields
- ✅ Use optional chaining `?.`
- ✅ Provide default values `??`
- ✅ Log errors with context

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + S` | Save workflow |
| `Ctrl/Cmd + Enter` | Execute workflow |
| `Tab` | Add new node |
| `Delete` | Delete selected |
| `Ctrl/Cmd + Z` | Undo |
| `Ctrl/Cmd + C` | Copy |
| `Ctrl/Cmd + V` | Paste |
| `Space` | Toggle node |

---

## API Endpoints

```bash
# List workflows
GET /api/v1/workflows

# Get workflow
GET /api/v1/workflows/:id

# Execute workflow
POST /api/v1/workflows/:id/execute

# Authentication
Headers: X-N8N-API-KEY: your_api_key
```

---

## CLI Commands

```bash
# Start
n8n start

# Import/Export
n8n import:workflow --input=file.json
n8n export:workflow --id=123 --output=file.json

# Credentials
n8n import:credentials --input=creds.json
n8n export:credentials --all --output=creds.json

# User management
n8n user-management:reset
```

---

## Quick Checklist

### Before Production
- [ ] PostgreSQL configured
- [ ] HTTPS enabled
- [ ] Strong encryption key
- [ ] Error handling implemented
- [ ] Monitoring setup
- [ ] Backups configured
- [ ] Rate limiting enabled
- [ ] Credentials rotated

### Testing
- [ ] Test with valid data
- [ ] Test with invalid data
- [ ] Test error scenarios
- [ ] Test edge cases
- [ ] Load test if needed
- [ ] Verify all credentials
- [ ] Check rate limits

---

## Resources

- 📖 [Docs](https://docs.n8n.io)
- 💬 [Forum](https://community.n8n.io)
- 🎥 [YouTube](https://youtube.com/c/n8n-io)
- 🐙 [GitHub](https://github.com/n8n-io/n8n)
- 📝 [Templates](https://n8n.io/workflows)
