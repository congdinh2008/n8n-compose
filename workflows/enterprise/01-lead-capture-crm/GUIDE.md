# 🎯 Lead Capture & CRM

> **File:** `workflow.json`
> **Độ khó:** ⭐⭐⭐
> **Thời gian setup:** ~25 phút

---

## Mục tiêu

Tự động hóa quy trình tiếp nhận và xử lý lead từ website form:
- Validate data (email, phone VN format)
- Check duplicate lead
- Lead scoring theo nguồn
- Welcome email tự động
- Notify sales team
- Route lead theo department

---

## Đối tượng sử dụng

**Doanh nghiệp** — phù hợp cho:
- Công ty nhỏ và startups
- Team sales cần tự động hóa lead capture
- Marketing team muốn track lead sources
- Bất kỳ ai có website form và cần xử lý lead tự động

---

## Sơ đồ luồng

```
[Webhook (POST /webhook/lead-capture)]
         │
         ▼
[Validate & Score Lead]
         │
         ▼
[IF: Valid Data?]
    │ Yes               │ No
    ▼                   ▼
[Check Duplicate]     [Return Error 400]
    │
    ▼
[Determine: New or Duplicate]
    │
    ▼
[IF: Duplicate?]
    │ No (new)                │ Yes (existing)
    ▼                         ▼
[Create New Lead]           [Update Existing Lead]
    │                              │
    ▼                              ▼
[Send Welcome Email]          [Route Lead by Source]
    │
    ▼
[Notify Sales Team]
```

---

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Webhook | Webhook | POST /webhook/lead-capture | None |
| Validate & Score | Code | Validate fields, phone VN, scoring | None |
| IF: Valid | IF | valid === true | None |
| Return Error | Respond to Webhook | HTTP 400 + error details | None |
| Check Duplicate | Google Sheets | Search by email | Google Sheets OAuth2 |
| Determine | Code | Compare search results | None |
| IF: Duplicate | IF | is_duplicate === true | None |
| Create Lead | Google Sheets | Append row | Google Sheets OAuth2 |
| Update Lead | Google Sheets | Update by email match | Google Sheets OAuth2 |
| Welcome Email | Gmail | Send welcome template | Gmail OAuth2 |
| Notify Team | Telegram | Send lead details | Telegram Bot Token |
| Route Lead | Code | Source → department mapping | None |

---

## Cài đặt

### Bước 1: Tạo Google Sheets

1. Tạo Google Sheet mới: [sheets.new](https://sheets.new)
2. Đặt tên: **"CRM Leads"**
3. Đặt headers row 1:

| A | B | C | D | E | F | G | H | I | J |
|---|---|---|---|---|---|---|---|---|---|
| Name | Email | Phone | Source | Message | Status | Lead_Score | Priority | Created_At | Vietnam_Time |

4. Copy **Sheet ID** từ URL

### Bước 2: Cấu hình Credentials

| Credential | Cách tạo |
|-----------|----------|
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail → Connect |
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |
| **Telegram Bot** | @BotFather → /newbot → Lấy token → n8n → Add Telegram Bot |

### Bước 3: Import Workflow

1. **n8n** → Workflows → Add workflow → Import from File
2. Chọn `workflows/enterprise/01-lead-capture-crm/workflow.json`
3. Cấu hình:
   - **Check Duplicate**: Gán credential + Sheet ID
   - **Create Lead**: Gán credential + Sheet ID
   - **Update Lead**: Gán credential + Sheet ID
   - **Welcome Email**: Gán Gmail credential, customize email
   - **Notify Team**: Gán Telegram credential + Chat ID
4. **Save** → **Activate**

### Bước 4: Customize Lead Scoring

Mở node **"Validate & Score Lead"**:

```javascript
const sourceScores = {
  'referral': 90,    // Giới thiệu (highest quality)
  'website': 70,     // Website organic
  'facebook': 60,    // Facebook ads
  'google': 65,      // Google ads
  'ads': 50,         // Ads chung
  'event': 80,       // Event (high intent)
  'email': 40        // Email marketing
};
```

Điều chỉnh scores theo chất lượng lead thực tế từ các nguồn.

### Bước 5: Customize Routing

Mở node **"Route Lead by Source"**:

```javascript
const routing = {
  'website': { team: 'sales', channel: '#sales-website' },
  'referral': { team: 'sales', channel: '#sales-referral' },
  'facebook': { team: 'marketing', channel: '#marketing-fb' },
  'google': { team: 'marketing', channel: '#marketing-ads' },
  'ads': { team: 'ads', channel: '#ads-team' },
  'event': { team: 'sales', channel: '#sales-events' },
  'email': { team: 'marketing', channel: '#marketing-email' }
};
```

---

## Webhook Integration

### POST Request

```bash
curl -X POST https://n8n.yourdomain.com/webhook/lead-capture \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nguyễn Văn A",
    "email": "vana@email.com",
    "phone": "0901234567",
    "source": "website",
    "message": "Tôi quan tâm đến sản phẩm của bạn"
  }'
```

### Required Fields

| Field | Type | Required | Format |
|-------|------|----------|--------|
| name | string | ✅ | Any text |
| email | string | ✅ | user@domain.com |
| phone | string | ✅ | +84XXXXXXXXX hoặc 0XXXXXXXXXX |
| source | string | ❌ (default: website) | website, facebook, google, referral, event, ads, email |
| message | string | ❌ | Any text |

### Success Response (200)

```json
{
  "success": true,
  "message": "Lead created successfully",
  "lead": {
    "name": "Nguyễn Văn A",
    "email": "vana@email.com",
    "lead_score": 70,
    "priority": "medium"
  }
}
```

### Error Response (400)

```json
{
  "success": false,
  "error": "Dữ liệu không hợp lệ",
  "details": [
    "Thiếu trường bắt buộc: email",
    "Số điện thoại không hợp lệ"
  ]
}
```

---

## Test

### Test với curl

```bash
# Test valid lead
curl -X POST http://localhost:5678/webhook/lead-capture \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Trần Thị B",
    "email": "thib@email.com",
    "phone": "+84901234567",
    "source": "referral",
    "message": "Được giới thiệu bởi anh A"
  }'

# Test invalid lead (missing email)
curl -X POST http://localhost:5678/webhook/lead-capture \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "phone": "0901234567"
  }'
```

### Test từ Website Form

Thêm form HTML vào website:

```html
<form id="leadForm">
  <input type="text" name="name" placeholder="Họ và tên" required>
  <input type="email" name="email" placeholder="Email" required>
  <input type="tel" name="phone" placeholder="Số điện thoại" required>
  <select name="source">
    <option value="website">Website</option>
    <option value="facebook">Facebook</option>
    <option value="google">Google</option>
  </select>
  <textarea name="message" placeholder="Tin nhắn"></textarea>
  <button type="submit">Gửi</button>
</form>

<script>
document.getElementById('leadForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const formData = new FormData(e.target);
  const data = Object.fromEntries(formData);
  
  const response = await fetch('https://n8n.yourdomain.com/webhook/lead-capture', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
  
  const result = await response.json();
  if (result.success) {
    alert('Cảm ơn bạn! Chúng tôi sẽ liên hệ sớm.');
  } else {
    alert('Lỗi: ' + result.details.join(', '));
  }
});
</script>
```

### Expected Results

| Input | Result |
|-------|--------|
| Valid lead, new email | Created in Sheets, welcome email sent, team notified |
| Valid lead, existing email | Updated in Sheets, routed by source |
| Missing required field | HTTP 400 with error details |
| Invalid phone format | HTTP 400 with phone validation error |

---

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Webhook 404 | Workflow chưa Activate | Toggle Active ON |
| Webhook 500 | Lỗi trong Code node | Kiểm tra Execution log |
| Google Sheets lỗi | Sheet ID sai hoặc credential | Kiểm tra Sheet ID + reconnect OAuth2 |
| Email không gửi được | Gmail credential hết hạn | Reconnect Gmail OAuth2 |
| Telegram không gửi | Bot token hoặc chat_id sai | Kiểm tra @BotFather |
| Duplicate không detect | Search query sai | Kiểm tra column name trong Sheets (phải là "Email") |
| Phone validation fail | Format khác | Kiểm tra regex trong Code node: `^(\+84\|0)[0-9]{9,10}$` |

---

## ⚠️ Lưu ý Community Version

1. **Webhook URL**: Cần public URL để website gọi được. Nếu test local, dùng **ngrok**:
   ```bash
   ngrok http 5678
   ```
   → Dùng URL ngrok cho webhook.

2. **No Webhook Authentication**: Community version không có built-in webhook auth. Nếu cần security:
   - Thêm API key header trong Code node
   - Verify key ở đầu workflow
   - Hoặc dùng reverse proxy (Nginx) với basic auth

3. **Concurrent Executions**: Community version không có queue mode. Nếu có nhiều submissions cùng lúc (100+), executions có thể bị delay.

4. **SQLite → PostgreSQL**: Default database là SQLite. Cho production với nhiều leads, nên switch sang PostgreSQL:
   ```yaml
   # docker-compose.yml
   environment:
     - DB_TYPE=postgresdb
     - DB_POSTGRESDB_HOST=postgres
     - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
   ```

5. **Google Sheets as CRM**: Google Sheets works cho small teams (< 1000 leads). Khi lớn hơn, nên dùng:
   - **Airtable** (có n8n node)
   - **HubSpot** (có n8n node)
   - **PostgreSQL** (dùng PostgreSQL node)

---

## Mở rộng

### 1. CRM Integration (HubSpot/Airtable)

Thay thế Google Sheets bằng CRM thực:

```
Validate → Check Duplicate (HubSpot) → Create Contact (HubSpot) → ...
```

### 2. Email Sequence

Thêm nurture sequence:

```
Create Lead → Wait (2 days) → Send Follow-up #1 → Wait (3 days) → Send Follow-up #2
```

### 3. AI Lead Qualification

```
Create Lead → AI Scoring (OpenAI) → Update Score → Route (High → Sales, Low → Nurture)
```

### 4. Dashboard & Reporting

```
Schedule (Daily) → Query Sheets → Generate Report → Send to Management
```

---

## Credits

- **Tác giả:** n8n-compose project
- **Phiên bản:** 1.0.0
- **Cập nhật:** 2026-05-05
