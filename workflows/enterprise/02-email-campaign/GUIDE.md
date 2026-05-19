# 📧 Enterprise: Email Campaign Automation

## Mục tiêu
Tự động hóa **email campaign welcome series**:
1. Immediate: Welcome Email #1
2. Wait 2 days: Getting Started #2
3. Wait 3 days: Advanced Tips #3 (IF opened #2) OR Resend #2b (IF not opened)
4. Wait 5 days: Special Offer #4
5. Track all sends/opens in Google Sheets

## Đối tượng sử dụng
**Doanh nghiệp** - Marketing teams, onboarding new users, customer nurturing.

## Sơ đồ luồng
```
[Webhook: New User Signup]
         │
         ▼
[Send Welcome Email #1]
  (Immediate)
         │
         ▼
[Wait 2 Days]
         │
         ▼
[Send Getting Started #2]
         │
         ▼
[Wait 3 Days]
         │
         ▼
[IF: Opened Previous?]
    │ yes        │ no
    ▼            ▼
[Send        [Resend #2b
Advanced     (Different
Tips #3]      subject)]
    │            │
    └─────┬──────┘
          ▼
   [Wait 5 Days]
          │
          ▼
   [Send Offer #4]
          │
          ▼
   [Log to Google Sheets]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Webhook (New Signup) | Webhook | POST /webhook/new-user | None |
| Send Welcome #1 | Gmail/SendGrid | Welcome template | Gmail OAuth2 |
| Wait 2 Days | Wait | 2 days | None |
| Send Getting Started #2 | Gmail/SendGrid | Guide template | Gmail OAuth2 |
| Wait 3 Days | Wait | 3 days | None |
| Check Email Open | Code/Webhook | Track open event | None |
| IF: Opened? | IF | Check open flag | None |
| Send Advanced Tips #3 | Gmail/SendGrid | Tips template | Gmail OAuth2 |
| Resend #2b | Gmail/SendGrid | Alternative subject | Gmail OAuth2 |
| Wait 5 Days | Wait | 5 days | None |
| Send Special Offer #4 | Gmail/SendGrid | Offer template | Gmail OAuth2 |
| Log to Sheets | Google Sheets | Campaign tracking | Google Sheets OAuth2 |

## Cài đặt

### Bước 1: Tạo Google Sheets Campaign Tracker

| email | user_id | step_1_sent | step_2_sent | step_3_sent | step_4_sent | opened | converted |
|-------|---------|-------------|-------------|-------------|-------------|--------|-----------|
| user@email.com | 123 | 2026-05-05 | 2026-05-07 | 2026-05-10 | | true | false |

### Bước 2: Cấu hình Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail → Connect |
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |

### Bước 3: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/enterprise/02-email-campaign/workflow.json`
4. Click **Import**

### Bước 4: Customize Email Templates

**Email #1: Welcome**
```
Subject: Chào mừng bạn đến với [Product]! 👋

Body:
Chào {{ $json.name }},

Cảm ơn bạn đã đăng ký! Chúng tôi rất vui khi có bạn ở đây.

Bắt đầu ngay:
1. Hoàn thành profile
2. Kết nối integration đầu tiên
3. Tạo workflow đầu tiên

Cần hỗ trợ? Reply email này nhé!

Trân trọng,
Team [Product]
```

**Email #2: Getting Started**
```
Subject: Hướng dẫn bắt đầu 🚀
```

**Email #3: Advanced Tips**
```
Subject: Mẹo nâng cao bạn nên biết 💡
```

**Email #4: Special Offer**
```
Subject: Ưu đãi đặc biệt dành cho bạn 🎁
```

### Bước 5: Test

**Test bằng curl:**
```bash
curl -X POST https://your-n8n.com/webhook/new-user \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@email.com",
    "name": "Nguyễn Văn A"
  }'
```

**Kiểm tra:**
1. ✅ Email #1 gửi ngay lập tức?
2. ✅ Email #2 gửi sau 2 ngày? (hoặc dùng Test mode để skip wait)
3. ✅ Tracking log vào Sheets?

## ⚠️ Lưu ý Community Version

- ✅ **Wait nodes** hoạt động tốt trong community
- ✅ **Gmail node** có sẵn
- ⚠️ **Workflow phải Active** để wait nodes hoạt động
- ⚠️ **Test mode** sẽ skip wait nodes (dùng để test nhanh)
- 💡 **Tip**: Dùng SendGrid node thay Gmail để có tracking opens/clicks

## Mở rộng

### Thêm Email Open Tracking
Dùng webhook tracking pixels:
```
Email contains tracking pixel → Webhook fires → Update Sheets
```

### Thêm A/B Testing
Split test email subjects:
```
IF user_id % 2 == 0 → Subject A
ELSE → Subject B
```

### Thêm Unsubscribe Handling
```
Webhook /unsubscribe → Update Sheets (set unsubscribed = true)
```

### Thêm Segmentation
Phân loại users trước khi gửi:
```javascript
const segment = user.plan === 'premium' ? 'vip' : 'standard';
// Send different content based on segment
```
