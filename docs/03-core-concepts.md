# 🔑 Khái niệm cốt lõi của N8N

## 📦 Workflow

**Workflow** là đơn vị cơ bản nhất trong n8n - một chuỗi các bước tự động hóa được kết nối với nhau.

### Cấu trúc Workflow

```json
{
  "name": "My Workflow",
  "nodes": [
    {
      "parameters": {},
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1.1,
      "position": [250, 300]
    },
    {
      "parameters": {},
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [500, 300]
    }
  ],
  "connections": {
    "Schedule Trigger": {
      "main": [
        [
          {
            "node": "HTTP Request",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

### Workflow Lifecycle

1. **Draft**: Đang được chỉnh sửa
2. **Active**: Sẵn sàng thực thi (trigger hoạt động)
3. **Deactivated**: Tạm dừng
4. **Archived**: Lưu trữ (không thể active)

---

## 🔵 Nodes

**Nodes** là building blocks của workflow. Mỗi node thực hiện một hành động cụ thể.

### Các loại Nodes

#### 1. Trigger Nodes
Khởi động workflow execution

```
┌─────────────────────────────────────┐
│     Schedule Trigger                │
│  • Chạy theo cron schedule          │
│  • Ví dụ: Mỗi giờ, mỗi ngày         │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│     Webhook Trigger                 │
│  • Chạy khi nhận HTTP request       │
│  • RESTful API endpoint             │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│     App Trigger                     │
│  • Gmail, Slack, Stripe events      │
│  • Push hoặc Poll-based             │
└─────────────────────────────────────┘
```

**Ví dụ triggers phổ biến:**
- `Schedule Trigger`: Cron-based execution
- `Webhook Trigger`: HTTP endpoint
- `Gmail Trigger`: Email mới
- `Stripe Trigger`: Payment events
- `Slack Trigger`: Message events

#### 2. Core Nodes
Nodes cơ bản built-in

```javascript
// Code Node - JavaScript
const items = $input.all();
return items.map(item => ({
  json: {
    ...item.json,
    processed: true,
    timestamp: new Date().toISOString()
  }
}));

// Code Node - Python
import json

items = input.all()
return [
  {
    "json": {
      **item.json,
      "processed": True,
      "timestamp": datetime.now().isoformat()
    }
  }
  for item in items
]
```

**Core nodes quan trọng:**
- `Code`: JavaScript/Python execution
- `HTTP Request`: API calls
- `IF`: Conditional branching
- `Switch`: Multi-way branching
- `Merge`: Combine data streams
- `Set`: Transform data
- `Aggregate`: Group items
- `Split Out`: Expand arrays
- `Filter`: Filter items
- `Wait`: Delay execution
- `Loop`: Iterate over items

#### 3. App Nodes
Tích hợp với external services

```
Communication:
├── Slack (send message, create channel)
├── Gmail (send email, read inbox)
├── Discord (post message)
└── Microsoft Teams

Database:
├── PostgreSQL (query, insert, update)
├── MySQL
├── MongoDB
└── Redis

Storage:
├── Google Drive (upload, download)
├── Dropbox
├── AWS S3
└── OneDrive

CRM:
├── HubSpot
├── Salesforce
├── Pipedrive
└── Zoho
```

#### 4. AI/LangChain Nodes
AI-powered nodes

```
AI Agent Node
├── LLM Models (OpenAI, Anthropic, Ollama)
├── Tools (HTTP Request, Code, Database)
├── Memory (Conversation, Buffer)
└── Output Parsers

Vector Store Nodes
├── Pinecone
├── Qdrant
├── Milvus
└── Chroma
```

### Node Anatomy

```
┌──────────────────────────────────────┐
│           Node Structure             │
├──────────────────────────────────────┤
│  Inputs:  [Main] [AI] [Vector]       │
│                                      │
│  ┌────────────────────────────────┐  │
│  │    Node Configuration          │  │
│  │  • Resource                     │  │
│  │  • Operation                    │  │
│  │  • Parameters                   │  │
│  │  • Credentials                  │  │
│  └────────────────────────────────┘  │
│                                      │
│  Outputs: [Success] [Error] [AI]     │
└──────────────────────────────────────┘
```

---

## 🔗 Connections

**Connections** định nghĩa luồng dữ liệu và execution giữa các nodes.

### Connection Types

#### 1. Main Connection
Luồng dữ liệu chính (JSON items)

```
Node A ──────► Node B
  │               │
  │  [{json:      │  [{json:
  │    data: 1}]  │    data: 1,
  │               │    processed: true}]
  └─ JSON items ─►┘
```

#### 2. AI Connection
Cho LangChain/AI nodes

```
AI Agent ──(AI)──► LLM Model
     │
     └──(AI)──► Tool
```

#### 3. Vector Store Connection
Cho embedding và retrieval

```
Embedding ──(Vector)──► Vector Store
```

### Connection Patterns

```
Sequential:
A ──► B ──► C

Parallel:
    ┌──► B
A ──┤
    └──► C

Conditional:
    ┌──(true)──► B
A ─┤
    └──(false)─► C

Merge:
B ──►
     ──► D
C ──►
```

---

## 📊 Data Structure

### JSON Items

n8n xử lý data dưới dạng **array of JSON objects** gọi là "items".

```javascript
// Item structure
{
  "json": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}

// Binary data (files, images)
{
  "json": {
    "filename": "report.pdf"
  },
  "binary": {
    "data": {
      "mimeType": "application/pdf",
      "fileName": "report.pdf",
      "data": "<base64_encoded_data>"
    }
  }
}
```

### Data Flow

```
┌─────────┐
│Trigger  │  Output: [{json: {event: "new_user"}}]
└────┬────┘
     │
     ▼
┌─────────┐
│HTTP Req │  Input:  [{json: {event: "new_user"}}]
│         │  Output: [{json: {id: 123, name: "John"}}]
└────┬────┘
     │
     ▼
┌─────────┐
│Code     │  Input:  [{json: {id: 123, name: "John"}}]
│         │  Output: [{json: {id: 123, greeting: "Hi John!"}}]
└────┬────┘
     │
     ▼
```

### Item Linking

Giữ quan hệ giữa parent/child items:

```javascript
// Split Out tạo child items
{
  "json": {
    "orderId": 1,
    "items": [
      {"product": "A", "qty": 2},
      {"product": "B", "qty": 1}
    ]
  }
}

// Sau Split Out (linked to parent):
[
  {"json": {"orderId": 1, "product": "A", "qty": 2}},
  {"json": {"orderId": 1, "product": "B", "qty": 1}}
]
```

---

## 🔐 Credentials

**Credentials** lưu trữ thông tin xác thực một cách bảo mật.

### Credential Types

```
API Key:
├── Header: "Authorization: Bearer <token>"
└── Query: "?api_key=<key>"

OAuth2:
├── Authorization Code Flow
├── Client Credentials Flow
└── PKCE Flow

Basic Auth:
├── Username + Password
└── Base64 encoded

Service Account:
├── JSON key file (Google)
└── Private key JWT
```

### Best Practices

```bash
# ✅ DO
- Sử dụng credential sharing có chọn lọc
- Rotate tokens định kỳ
- Sử dụng environment variables cho secrets
- Enable encryption key

# ❌ DON'T
- Hardcode secrets trong workflow
- Share credentials quá rộng rãi
- Commit encryption key vào git
- Sử dụng default encryption key
```

---

## 💬 Expressions

**Expressions** là JavaScript inline để transform data.

### Syntax

```javascript
// Reference node output
{{ $json.name }}
{{ $node["HTTP Request"].json.id }}

// Built-in helpers
{{ $now.format('yyyy-MM-dd') }}
{{ $json.email.toLowerCase() }}
{{ Math.round($json.price * 100) / 100 }}

// Conditional
{{ $json.status === 'active' ? '✅' : '❌' }}

// Array operations
{{ $json.tags.join(', ') }}
{{ $json.items.filter(item => item.price > 100) }}
```

### Context Variables

```javascript
$now              // Current datetime
$today            // Today's date
$today.startOf('day')
$env              // Environment variables
$workflow         // Workflow metadata
$node             // Current node info
```

---

## ⚡ Execution

### Execution Modes

1. **Manual**: Test từ UI
2. **Partial**: Execute từ node cụ thể
3. **Production**: Trigger tự động

### Execution Lifecycle

```
1. Trigger fires
   ↓
2. Load workflow
   ↓
3. Execute nodes (sequential/parallel)
   ↓
4. Handle errors (if any)
   ↓
5. Save execution data
   ↓
6. Return results
```

### Execution Data

```javascript
// Execution metadata
{
  "id": "123",
  "mode": "manual",
  "startedAt": "2024-01-01T00:00:00Z",
  "stoppedAt": "2024-01-01T00:00:05Z",
  "status": "success", // | 'error' | 'waiting'
  "workflowId": "456"
}
```

---

## 🎯 Workflow Settings

### General Settings

```
Settings → Workflow Settings:
├── Execution order: v0 (legacy) | v1 (default)
├── Error workflow: [Select error handler workflow]
├── Save execution data: Yes/No
├── Save manual executions: Yes/No
└── Timezone: Asia/Ho_Chi_Minh
```

### Error Handling

```
Node Settings → On Error:
├── Stop Workflow (default)
├── Continue (ignore error)
└── Go to error node
```

---

## 📝 Sticky Notes

**Sticky Notes** để document workflow.

```
┌─────────────────────────────────┐
│ 📌 Fetch users from API         │
│    • Paginate qua tất cả pages  │
│    • Filter active users only   │
│    • Transform to standard fmt  │
└─────────────────────────────────┘
```

---

## 🚀 Next Steps

→ [Workflow Basics](04-workflow-basics.md)
→ [Expressions & JavaScript](05-expressions-javascript.md)

## 📚 Tham khảo

- [n8n Data Structure](https://docs.n8n.io/data/)
- [Node Documentation](https://docs.n8n.io/integrations/)
- [Expression Reference](https://docs.n8n.io/data/expression-reference/)
