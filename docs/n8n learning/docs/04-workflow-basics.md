# 🚀 Làm quen với Workflow

## Tạo workflow đầu tiên

### Bước 1: Truy cập Editor

```
http://localhost:5678
```

### Bước 2: Tạo workflow mới

1. Click **"Add workflow"** từ dashboard
2. Hoặc nhấn **Ctrl/Cmd + N**

### Bước 3: Thêm Trigger Node

1. Click nút **"+"** trên canvas
2. Search **"Schedule Trigger"**
3. Click để thêm vào canvas

**Cấu hình Schedule:**
```
Trigger Interval: 
  ○ Every hour
  ● Every day
  ○ Every week
  
At: 09:00
Timezone: Asia/Ho_Chi_Minh
```

### Bước 4: Thêm HTTP Request Node

1. Kéo từ **Schedule Trigger** node
2. Search **"HTTP Request"**
3. Cấu hình:

```
Method: GET
URL: https://api.openweathermap.org/data/2.5/weather
Authentication: Predefined Credential Type
  - Type: OpenWeatherMap API
  - API Key: your_api_key

Query Parameters:
  q: Hanoi
  units: metric
```

### Bước 5: Transform data với Set Node

```
Keep Only Set: ✅ true
Parameters:
  - city: ={{ $json.name }}
  - temperature: ={{ $json.main.temp }}
  - description: ={{ $json.weather[0].description }}
  - timestamp: ={{ $now.format('yyyy-MM-dd HH:mm') }}
```

### Bước 6: Gửi email với Gmail Node

```
Resource: Message
Operation: Send
To: your-email@gmail.com
Subject: =Thời tiết hôm nay tại {{ $json.city }}
Email Format: HTML
Message: |
  <h2>Báo cáo thời tiết</h2>
  <p><strong>Địa điểm:</strong> {{ $json.city }}</p>
  <p><strong>Nhiệt độ:</strong> {{ $json.temperature }}°C</p>
  <p><strong>Mô tả:</strong> {{ $json.description }}</p>
```

### Bước 7: Test workflow

1. Nhấn **"Test workflow"** (top right)
2. Hoặc **"Execute node"** trên từng node
3. Kiểm tra output ở mỗi bước

### Bước 8: Activate workflow

1. Toggle **"Inactive"** → **"Active"** (top right)
2. Workflow sẽ chạy tự động theo schedule

---

## 🎨 Editor UI Explained

### Layout

```
┌──────────────────────────────────────────────────┐
│  Header Bar                                       │
│  [←] Workflow Name  [Save]  [Test]  [Active ⚡]  │
├──────────────────────────────────────────────────┤
│                                                   │
│  ┌─────────────────────────────────────────┐     │
│  │         Canvas (Workflow Area)          │     │
│  │    [Trigger] ──► [Node] ──► [Node]      │     │
│  └─────────────────────────────────────────┘     │
│                                                   │
├──────────────────────────────────────────────────┤
│  Bottom Panel (Execution Output)                  │
│  [JSON] [Table] [Schema] [Binary]                │
└──────────────────────────────────────────────────┘
```

### Keyboard Shortcuts

```
Ctrl/Cmd + N          : New workflow
Ctrl/Cmd + S          : Save workflow
Ctrl/Cmd + Enter      : Test workflow
Ctrl/Cmd + Z          : Undo
Delete                : Delete selected
Space                 : Execute node
Tab                   : Add node
```

---

## 🔗 Connecting Nodes

### Basic Connection

```
Drag từ output handle (right side) của node A
  ↓
Drop vào input handle (left side) của node B
```

### Multiple Outputs

```
IF Node:
  ├─ true output  ──► Node B
  └─ false output ──► Node C
```

### Multiple Inputs (Merge Node)

```
Node A ──►
           ──► Merge Node ──► Node D
Node B ──►
```

---

## 🧪 Testing Workflows

### Manual Execution

1. Click **"Test workflow"**
2. Workflow runs từ đầu đến cuối
3. Xem output ở mỗi node

### Partial Execution

1. Click **"Execute node"** trên node cụ thể
2. Chỉ chạy từ node đó trở đi
3. Hữu ích để debug

### Pinning Data

1. Chạy workflow
2. Click **"Pin"** trên output data
3. Data được lưu để test lại
4. Không cần trigger thật

---

## 💾 Import/Export Workflows

### Export

1. Mở workflow
2. Click **⋮** (top right)
3. **"Download workflow"**
4. File JSON được tải về

### Import

1. Click **"Add workflow"**
2. Click **⋮** → **"Import from File"**
3. Chọn file JSON
4. Review và **"Save"**

### Copy/Paste

```
Ctrl/Cmd + C          : Copy selected nodes
Ctrl/Cmd + V          : Paste nodes
Ctrl/Cmd + X          : Cut selected nodes
```

---

## 📋 Workflow ví dụ hoàn chỉnh

### Use Case: Daily Report Automation

```json
{
  "name": "Daily Sales Report",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [{ "field": "daily", "triggerAtHour": 8 }]
        }
      },
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1.1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "GET",
        "url": "https://api.example.com/sales",
        "sendQuery": true,
        "queryParameters": [
          {
            "name": "date",
            "value": "={{ $now.minus({days: 1}).format('yyyy-MM-dd') }}"
          }
        ]
      },
      "name": "Fetch Sales Data",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [500, 300]
    },
    {
      "parameters": {
        "jsCode": "const sales = $input.all();\nconst total = sales.reduce((sum, item) => sum + item.json.amount, 0);\nreturn [{ json: { totalRevenue: total, totalOrders: sales.length } }];"
      },
      "name": "Calculate Metrics",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [750, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "text",
              "value": "=📊 *Daily Sales Report*\n\n💰 Revenue: ${{ $json.totalRevenue.toLocaleString() }}\n📦 Orders: {{ $json.totalOrders }}"
            }
          ]
        }
      },
      "name": "Send to Slack",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [1000, 300]
    }
  ],
  "connections": {
    "Schedule Trigger": {
      "main": [[{ "node": "Fetch Sales Data", "type": "main", "index": 0 }]]
    },
    "Fetch Sales Data": {
      "main": [[{ "node": "Calculate Metrics", "type": "main", "index": 0 }]]
    },
    "Calculate Metrics": {
      "main": [[{ "node": "Send to Slack", "type": "main", "index": 0 }]]
    }
  }
}
```

---

## ✅ Checklist tạo workflow

- [ ] Workflow có tên rõ ràng, mô tả mục đích
- [ ] Trigger được cấu hình đúng
- [ ] Tất cả nodes được kết nối
- [ ] Credentials đã được setup
- [ ] Đã test manual execution
- [ ] Error handling đã được thêm
- [ ] Workflow được save
- [ ] Activated nếu cần chạy tự động

---

## 🚀 Next Steps

→ [Expressions & JavaScript](05-expressions-javascript.md)
→ [Code Node](06-code-node.md)
