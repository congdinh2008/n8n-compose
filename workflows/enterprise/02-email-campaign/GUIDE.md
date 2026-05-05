# 📧 Enterprise: Email Campaign (Welcome Series)

## Mục tiêu
Tự động hóa **email campaign welcome series** cho user mới signup:
- Email #1: Welcome (ngay lập tức)
- Email #2: Getting Started (sau 2 ngày)
- Email #3: Advanced Tips (sau 3 ngày nữa, nếu mở email #2) HOẶC Email #2b: Reminder (nếu không mở)

## Đối tượng sử dụng
**Doanh nghiệp** - Marketing teams, product teams, bất kỳ ai cần onboard user mới qua email sequence.

## Sơ đồ luồng
```
[Webhook: POST /webhook/new-signup]
         │
         ▼
[Validate Signup Data]
         │
         ▼
[Email #1: Welcome Email]
  (Gửi ngay)
         │
         ▼
[Wait 2 Days]
         │
         ▼
[Email #2: Getting Started]
         │
         ▼
[Log to Google Sheets]
         │
         ▼
[Wait 3 Days]
         │
         ▼
    IF: Opened Previous?
    │          │
    Yes        No
    │          │
    ▼          ▼
[Email #3   [Email #2b:
 Advanced]   Reminder]
         │         │
         └────┬────┘
              ▼
   [Return Success Response]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Webhook (New Signup) | Webhook | POST /webhook/new-signup | None |
| Validate Signup Data | Code | Email/name validation | None |
| Email #1: Welcome | Gmail | Welcome template | Gmail OAuth2 |
| Wait 2 Days | Wait | 2 days delay | None |
| Email #2: Getting Started | Gmail | Guide template | Gmail OAuth2 |
| Log Email #2 | Google Sheets | Append row | Google Sheets OAuth2 |
| Wait 3 Days | Wait | 3 days delay | None |
| IF: Opened? | IF | Check opens_tracked flag | None |
| Email #3: Advanced Tips | Gmail | Advanced template | Gmail OAuth2 |
| Email #2b: Reminder | Gmail | Reminder template | Gmail OAuth2 |

## Cài đặt

### Bước 1: Cấu hình Webhook

**Webhook URL:** `https://your-n8n-domain.com/webhook/new-signup`

**Request format:**
```bash
curl -X POST https://your-n8n.com/webhook/new-signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nguyễn Văn A",
    "email": "nguyenvana@email.com",
    "source": "Website"
  }'
```

### Bước 2: Chuẩn bị Google Sheets

Tạo Google Sheet để track campaign performance:

| email | name | campaign_id | email_number | sent_at | status | opened |
|-------|------|-------------|--------------|---------|--------|--------|
| a@email.com | Nguyễn A | CAMP-123 | 2 | 2026-05-07 | sent | false |

### Bước 3: Cấu hình Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail OAuth2 → Connect |
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |

### Bước 4: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/enterprise/02-email-campaign/workflow.json`
4. Click **Import**

### Bước 5: Customize Email Templates

**Mở từng Email node và thay thế:**

**1. Email #1: Welcome Email**
- Replace `[Product]` bằng tên sản phẩm của bạn
- Customize 3 bước khởi động
- Thêm link video hướng dẫn

**2. Email #2: Getting Started**
- Customize 3 tính năng chính
- Thêm link tài liệu và cộng đồng

**3. Email #3: Advanced Tips**
- Customize mẹo nâng cao
- Thêm link tutorials

**4. Email #2b: Reminder**
- Customize message nhẹ nhàng
- Thêm contact info

### Bước 6: Cấu hình Log to Google Sheets

- Mở node "Log Email #2 Sent"
- Set **Document ID** = Sheet ID
- Set **Sheet Name** = tên sheet

### Bước 7: Test

1. Gửi test request qua curl hoặc Postman
2. Kiểm tra:
   - ✅ Email #1 có đến ngay không?
   - ✅ Wait node có hoạt động không? (cần workflow Active)
   - ✅ Email #2 có gửi sau 2 ngày không?
   - ✅ Google Sheets có log không?
3. Test conditional logic:
   - Set `opens_tracked = true` → Kiểm tra Email #3
   - Set `opens_tracked = false` → Kiểm tra Email #2b

## Email Templates

### Email #1: Welcome (Immediate)
**Subject:** `Chào mừng {name} đến với [Product]! 👋`

**Nội dung:**
- Chào mừng
- 3 bước khởi động
- Link video hướng dẫn
- Contact info

### Email #2: Getting Started (Day 2)
**Subject:** `Hướng dẫn bắt đầu với [Product] 🚀`

**Nội dung:**
- 3 tính năng chính
- Link tài liệu chi tiết
- Link cộng đồng

### Email #3: Advanced Tips (Day 5, if opened)
**Subject:** `Mẹo nâng cao để tối ưu [Product] 💡`

**Nội dung:**
- Mẹo sử dụng nâng cao
- Link tutorials
- Khuyến khích khám phá

### Email #2b: Reminder (Day 5, if not opened)
**Subject:** `Bạn có cần hỗ trợ gì không? 🤔`

**Nội dung:**
- Nhắc nhở nhẹ nhàng
- Contact options
- Encouragement

## Tracking Email Opens

### Method 1: Webhook-based Tracking
Thêm tracking pixel vào email:
```html
<img src="https://your-n8n.com/webhook/email-opened?campaign_id={{campaign_id}}" width="1" height="1">
```

Tạo workflow riêng nhận webhook và update `opens_tracked` flag trong Google Sheets.

### Method 2: Link Tracking
Track khi user click links trong email:
```
Redirect link: https://your-n8n.com/webhook/link-click?url={original_url}&campaign_id={id}
```

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Webhook 404 | URL sai hoặc workflow chưa active | Kiểm tra URL và bật workflow |
| Email không gửi được | Gmail credential invalid | Reconnect Gmail OAuth2 |
| Wait node không hoạt động | Workflow chưa Active | Activate workflow (toggle Active) |
| Google Sheets error | Sheet ID sai | Kiểm tra Sheet ID và permissions |
| Conditional logic sai | opens_tracked flag không được update | Implement email open tracking |

## ⚠️ Lưu ý Community Version

- ✅ **Webhook node** hoạt động tốt
- ✅ **Gmail node** có sẵn
- ✅ **Wait nodes** hoạt động tốt (cần workflow Active)
- ⚠️ **Queue mode không available** — wait nodes có thể không chính xác nếu server restart
- ⚠️ **Email open tracking** cần custom implementation (webhook + tracking pixel)
- 💡 **Tip**: Dùng Google Sheets để track campaign performance và open rates

## Mở rộng

### Thêm A/B Testing
Test nhiều subject lines:
```javascript
const subjectA = "Chào mừng bạn! 👋";
const subjectB = "Welcome aboard! 🎉";
const variant = Math.random() > 0.5 ? 'A' : 'B';
const subject = variant === 'A' ? subjectA : subjectB;
```

### Thêm Re-engagement Campaign
Cho users không active sau 30 ngày:
```
Schedule (weekly) → Query inactive users → Send re-engagement email
```

### Thêm Unsubscribe Handling
Tự động handle unsubscribe requests:
```
Webhook (/unsubscribe) → Update Google Sheets (status = unsubscribed)
```

### Thêm Multi-language Support
Hỗ trợ tiếng Anh và tiếng Việt:
```javascript
const language = user.preferred_language || 'vi';
const templates = {
  vi: { welcome: "Chào mừng...", subject: "Chào mừng..." },
  en: { welcome: "Welcome...", subject: "Welcome..." }
};
```

### Integration với Website

**HTML Form:**
```html
<form action="https://your-n8n.com/webhook/new-signup" method="POST">
  <input type="text" name="name" required placeholder="Họ và tên">
  <input type="email" name="email" required placeholder="Email">
  <input type="hidden" name="source" value="Website Signup">
  <button type="submit">Sign Up</button>
</form>
```
