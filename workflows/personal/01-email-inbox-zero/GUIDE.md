# 📧 Personal: Email Inbox Zero

## Mục tiêu
Tự động **phân loại và xử lý email** đến để đạt **Inbox Zero**:
- Email quan trọng → Star + Notify qua Telegram
- Newsletter → Label + Archive
- Promotion → Label + Archive
- Bình thường → Giữ lại Inbox

## Đối tượng sử dụng
**Cá nhân** - Bất kỳ ai muốn tự động hóa việc quản lý email, giảm thời gian xử lý inbox.

## Sơ đồ luồng
```
[Gmail Trigger - Unread Emails]
         │
         ▼
[Classify Email Type]
  (Keyword matching + VIP list)
         │
         ▼
    IF: Important?
    │          │
    Yes        No
    │          │
    ▼          ▼
[Star +    IF: Newsletter?
 Notify]   │          │
           Yes        No
           │          │
           ▼          ▼
      [Label +    IF: Promotion?
       Archive]   │          │
                  Yes        No
                  │          │
                  ▼          ▼
             [Label +    [Keep in
              Archive]    Inbox]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Gmail Trigger | Gmail | Filter: unread only | Gmail OAuth2 |
| Classify Email Type | Code | Vietnamese keywords, VIP list | None |
| IF: Important? | IF | Check category = 'important' | None |
| Star Important Email | Gmail | Add STARRED label | Gmail OAuth2 |
| Notify via Telegram | Telegram | Custom chat ID | Telegram Bot Token |
| IF: Newsletter? | IF | Check category = 'newsletter' | None |
| IF: Promotion? | IF | Check category = 'promotion' | None |
| Apply Label | Gmail | Add category label | Gmail OAuth2 |
| Archive Email | Gmail | Archive message | Gmail OAuth2 |

## Cài đặt

### Bước 1: Chuẩn bị Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail OAuth2 → Connect |
| **Telegram Bot** (Optional) | Tạo bot qua @BotFather → Copy token → Add credentials |

### Bước 2: Tạo Gmail Labels

Trước khi import, tạo các labels trong Gmail:
1. Mở Gmail → Settings → Labels
2. Tạo labels:
   - `⭐ Important`
   - `📬 Newsletter`
   - `🏷️ Promotion`

### Bước 3: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/personal/01-email-inbox-zero/workflow.json`
4. Click **Import**

### Bước 4: Cấu hình

**1. Gmail Trigger:**
- Mở node "Gmail Trigger (New Email)"
- **Operation**: `messageReceived`
- **Filters**: `readStatus = unread`
- **Optional**: Thêm filter `from` để chỉ monitor emails từ sender cụ thể

**2. Classify Email Type:**
- Mở node "Classify Email Type"
- **Customize VIP senders list**:
```javascript
const vipSenders = [
  'boss@company.com',        // Thay bằng email sếp
  'manager@company.com',     // Thay bằng email quản lý
  'family@email.com',        // Email gia đình
  // Thêm email quan trọng khác
];
```
- **Review keywords** cho mỗi category và thêm/bớt theo nhu cầu

**3. Apply Label:**
- Mở node "Apply Label"
- Set **labelIds** phù hợp với labels đã tạo trong Gmail

**4. Notify via Telegram:**
- Set **Chat ID** = chat ID của bạn
- Gán Telegram credential
- **Hoặc xóa node này** nếu không dùng Telegram

### Bước 5: Test

1. Gửi email test đến inbox với các loại khác nhau:
   - Email từ VIP sender → Kiểm tra star + notify
   - Email có 'unsubscribe' → Kiểm tra archive
   - Email có 'giảm giá' → Kiểm tra archive
   - Email bình thường → Kiểm tra giữ lại inbox
2. Click **Test Workflow**
3. Kiểm tra kết quả trong Gmail

## Email Classification Rules

### Important (Star + Notify)
- Từ VIP senders list
- Chứa keywords: 'urgent', 'khẩn', 'important', 'gấp', 'deadline', 'hạn chót'

### Newsletter (Label + Archive)
- Chứa: 'unsubscribe', 'newsletter', 'digest', 'bản tin', 'hủy đăng ký'
- Từ: noreply, no-reply, do-not-reply

### Promotion (Label + Archive)
- Chứa: 'sale', 'discount', 'giảm giá', 'khuyến mãi', 'flash sale', 'ưu đãi'
- Events: 'black friday', 'tet sale', 'cyber monday'

### Normal (Keep in Inbox)
- Không match bất kỳ category nào ở trên

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Không trigger | Gmail credential invalid | Reconnect Gmail OAuth2 |
| Email không được phân loại | Keywords không match | Review và thêm keywords vào Code node |
| Label không được apply | Label chưa tạo trong Gmail | Tạo labels trước trong Gmail Settings |
| Telegram không gửi được | Bot token hoặc chat_id sai | Kiểm tra credentials |
| Archive không hoạt động | Gmail API permissions | Đảm bảo Gmail OAuth có full access |

## ⚠️ Lưu ý Community Version

- ✅ **Gmail node** có sẵn, chỉ cần OAuth2
- ✅ **Code node** hoạt động tốt cho classification
- ⚠️ **OAuth2 credentials** cần reconnect định kỳ (token expire)
- ⚠️ **Polling interval** - Gmail trigger poll mỗi 1-5 phút, không real-time
- 💡 **Tip**: Bắt đầu với classification đơn giản, sau đó refine keywords dần

## Mở rộng

### Thêm AI Classification
Dùng OpenAI node để AI phân loại email thông minh hơn:
```
Gmail Trigger → OpenAI (Classify) → Route based on AI response
```

### Thêm Auto-Reply
Tự động trả lời cho newsletters/promotions:
```javascript
// Thêm node gửi auto-reply
const autoReply = {
  to: email.from,
  subject: `Re: ${email.subject}`,
  body: "Cảm ơn bạn đã gửi email. Tôi sẽ phản hồi trong thời gian sớm nhất."
};
```

### Thêm Google Sheets Logging
Log tất cả emails đã xử lý:
| Column | Value |
|--------|-------|
| timestamp | `={{ $json.classified_at }}` |
| from | `={{ $json.from }}` |
| subject | `={{ $json.subject }}` |
| category | `={{ $json.category }}` |
| action | `={{ $json.action }}` |

### Thêm Snooze Functionality
Auto-snooze emails không quan trọng vào cuối ngày:
```
IF: Normal email AND time > 5 PM → Snooze until tomorrow 9 AM
```
