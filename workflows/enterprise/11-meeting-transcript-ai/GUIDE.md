# 📋 Meeting Transcript → AI Meeting Minutes

> **Tự động phân tích transcript cuộc họp bằng AI (Gemini / DeepSeek), tổng hợp thành biên bản chuẩn, gửi email cho toàn bộ attendees, lưu Google Sheets và thông báo Telegram.**
> **Phiên bản:** 1.0.0
> **Cập nhật:** 2026-05-11

---

## 🎯 Mục Tiêu

Workflow nhận transcript cuộc họp qua Webhook, sau đó:
1. **Phân tích** bằng AI (Gemini 2.0 Flash hoặc DeepSeek Chat)
2. **Tạo biên bản họp** chuẩn: tóm tắt, quyết định, action items
3. **Gửi email HTML** đẹp cho tất cả người tham dự
4. **Lưu log** vào Google Sheets để theo dõi
5. **Thông báo** tóm tắt qua Telegram (tuỳ chọn)
6. **Trả về JSON response** cho client

---

## 👥 Đối Tượng Sử Dụng

| Đối tượng | Mô tả |
|-----------|-------|
| Team leader / PM | Tự động hoá ghi chú sau mỗi cuộc họp |
| HR / Admin | Tổng hợp biên bản họp hàng tuần |
| Developer | Tích hợp vào pipeline CI/CD hoặc Slack bot |
| Startup / SME | Thay thế người ghi chú thủ công |

---

## 🗺️ Sơ Đồ Luồng

```
[📥 Webhook: POST /meeting-transcript]
           │
           ▼
[⚙️ Validate & Chuẩn Bị Data]
  - Kiểm tra transcript ≥ 50 ký tự
  - Chuẩn hóa ai_model (gemini/deepseek)
  - Parse attendees list
  - Tạo Request ID
           │
           ▼
[📝 Tạo AI Prompt]
  - Format ngày tiếng Việt
  - Build prompt yêu cầu JSON output
           │
           ▼
[🔀 IF: ai_model == 'gemini'?]
    │                    │
    ▼ (TRUE)             ▼ (FALSE)
[🤖 Gemini           [🤖 DeepSeek
 2.0 Flash]           Chat]
    │                    │
    └────────┬───────────┘
             ▼
[🔍 Parse Kết Quả AI]
  - Parse Gemini/DeepSeek format
  - Extract: summary, topics, decisions,
    action items, next steps
             │
             ▼
[✍️ Format Email & Thông Báo]
  - Render HTML email đẹp
  - Build Telegram message
  - Chuẩn bị Sheets row data
             │
    ┌────────┼────────────────────┐
    ▼        ▼                   ▼
[📊 Sheets] [📧 Gmail]    [🔀 IF Telegram?]
  Lưu log   Gửi email       │ YES  │ NO
                       [📱 Telegram] │
                             │       │
                             └───┬───┘
                                 ▼
                     [✅ Respond to Webhook]
                       Trả JSON success
```

---

## 📊 Nodes Chi Tiết

| # | Node | Type | Mô tả |
|---|------|------|-------|
| 1 | 📥 Webhook: Nhận Transcript | Webhook | Nhận POST request với transcript |
| 2 | ⚙️ Validate & Chuẩn Bị Data | Code | Validate input, tạo Request ID |
| 3 | 📝 Tạo AI Prompt | Code | Build prompt phân tích biên bản |
| 4 | 🔀 IF: Dùng Gemini? | IF | Route đến Gemini hoặc DeepSeek |
| 5 | 🤖 Gemini: Phân Tích | HTTP Request | Gọi Gemini 2.0 Flash API |
| 6 | 🤖 DeepSeek: Phân Tích | HTTP Request | Gọi DeepSeek Chat API |
| 7 | 🔍 Parse Kết Quả AI | Code | Parse JSON response từ AI |
| 8 | ✍️ Format Email & Thông Báo | Code | Render HTML email + Telegram |
| 9 | 📊 Google Sheets: Lưu Log | Google Sheets | Append row vào sheet |
| 10 | 📧 Gmail: Gửi Biên Bản | Gmail | Gửi email HTML cho attendees |
| 11 | 🔀 IF: Gửi Telegram? | IF | Kiểm tra có chat ID không |
| 12 | 📱 Telegram: Thông Báo | Telegram | Gửi tóm tắt lên Telegram |
| 13 | ✅ Respond to Webhook | Respond to Webhook | Trả JSON response |

---

## 🔑 Credentials Cần Chuẩn Bị

### 1. Google Gemini API (nếu dùng `ai_model: "gemini"`)

**Lấy API Key:**
1. Truy cập [Google AI Studio](https://aistudio.google.com)
2. Click **Get API Key** → **Create API Key**
3. Copy API Key

**Cài trong n8n:**
```
Settings → Credentials → Add New Credential
→ Tìm: "Google Gemini(PaLM) Api"
→ API Key: [paste key vào đây]
→ Save
```

> **Lưu ý model:** Workflow dùng `gemini-2.0-flash` (rẻ, nhanh ~2-5s/request).
> Có thể đổi sang `gemini-1.5-pro` cho chất lượng cao hơn (chậm hơn và tốn quota hơn).

---

### 2. DeepSeek API (nếu dùng `ai_model: "deepseek"`)

**Lấy API Key:**
1. Đăng ký tại [platform.deepseek.com](https://platform.deepseek.com)
2. API Keys → **Create new key**
3. Copy API Key

**Cài trong n8n:**
```
Settings → Credentials → Add New Credential
→ Tìm: "Header Auth"
→ Name: Authorization
→ Value: Bearer YOUR_DEEPSEEK_API_KEY
→ Save
```

> **Tại sao chọn DeepSeek?**
> - Chi phí rẻ hơn GPT-4 ~10-20 lần
> - Hỗ trợ tiếng Việt tốt
> - API tương thích OpenAI format
> - `deepseek-chat` đủ mạnh để phân tích meeting

---

### 3. Gmail OAuth2

**Thiết lập:**
1. [Google Cloud Console](https://console.cloud.google.com) → Tạo project
2. **APIs & Services** → **Enable APIs** → bật **Gmail API**
3. **OAuth consent screen** → External → Add test user (email của bạn)
4. **Credentials** → **Create OAuth 2.0 Client ID** → Web Application
5. Authorized redirect URIs: `https://your-n8n.com/rest/oauth2-credential/callback`

**Cài trong n8n:**
```
Settings → Credentials → Add New Credential
→ Tìm: "Gmail OAuth2"
→ Client ID + Client Secret → Connect
→ Đăng nhập Google
```

---

### 4. Google Sheets OAuth2

Dùng cùng Google Cloud project với Gmail:
1. **APIs & Services** → **Enable APIs** → bật **Google Sheets API**

**Cài trong n8n:**
```
Settings → Credentials → Add New Credential
→ Tìm: "Google Sheets OAuth2"
→ Dùng cùng Client ID/Secret với Gmail
→ Connect → Đăng nhập Google
```

---

### 5. Telegram Bot

**Tạo Bot:**
1. Mở Telegram → tìm **@BotFather**
2. `/newbot` → đặt tên → đặt username
3. Copy **Bot Token** (dạng: `1234567890:ABCdef...`)

**Lấy Chat ID:**
```
1. Nhắn tin /start cho bot
2. Mở: https://api.telegram.org/bot{TOKEN}/getUpdates
3. Tìm: result[0].message.chat.id
```

**Cài trong n8n:**
```
Settings → Credentials → Add New Credential
→ Tìm: "Telegram"
→ Access Token: [Bot Token]
→ Save
```

---

## 🛠️ Cài Đặt Step-by-Step

### Bước 1: Import Workflow

```
n8n Dashboard → Add Workflow → Import from File
→ Chọn: enterprise/11-meeting-transcript-ai/workflow.json
```

### Bước 2: Cài Credentials vào Nodes

Mở từng node và chọn credentials:

| Node | Credential |
|------|-----------|
| 🤖 Gemini | Google Gemini(PaLM) Api account |
| 🤖 DeepSeek | Header Auth (DeepSeek API Key) |
| 📊 Google Sheets | Google Sheets OAuth2 |
| 📧 Gmail | Gmail OAuth2 |
| 📱 Telegram | Telegram Bot |

### Bước 3: Tạo Google Sheet

Tạo Google Sheet mới với tab tên **"Meeting Log"**:

**Columns (Row 1 - Headers):**
```
A: Request ID
B: Meeting Title
C: Meeting Date
D: Attendees
E: Attendees Count
F: Summary
G: Action Items Count
H: Decisions Count
I: Topics Count
J: Effectiveness Score
K: Next Meeting
L: AI Model
M: Email Recipients
N: Processed At
O: Action Items JSON
P: Decisions JSON
```

**Lấy Sheet ID:**
URL của sheet: `https://docs.google.com/spreadsheets/d/{SHEET_ID}/edit`

### Bước 4: Test với pinData

1. Click node **📥 Webhook: Nhận Transcript**
2. Xem **pinData** mẫu có sẵn (transcript về Sprint Review)
3. Click **"Test Workflow"** (không cần gửi request thật)
4. Kiểm tra kết quả từng node

### Bước 5: Activate

Toggle **Active** (góc trên phải) → **ON**

---

## 📡 API Reference

### Endpoint

```
POST {n8n_url}/webhook/meeting-transcript
Content-Type: application/json
```

### Request Body

```json
{
  "meeting_title": "Sprint 3 Review & Sprint 4 Planning",
  "meeting_date": "2026-05-11",
  "attendees": [
    "minh@company.vn",
    "hoa@company.vn"
  ],
  "attendee_names": [
    "Nguyễn Văn Minh (PM)",
    "Trần Thị Hoa (Dev)"
  ],
  "transcript": "...(nội dung transcript từ cuộc họp)...",
  "ai_model": "gemini",
  "organizer_email": "minh@company.vn",
  "notification_chat_id": "123456789",
  "sheet_id": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms"
}
```

### Fields

| Field | Required | Mô tả |
|-------|----------|-------|
| `meeting_title` | Không | Tên cuộc họp (mặc định: "Cuộc Họp Không Tên") |
| `meeting_date` | Không | Ngày họp YYYY-MM-DD (mặc định: hôm nay) |
| `attendees` | Không | Danh sách email người tham dự |
| `attendee_names` | Không | Tên hiển thị (dùng nếu khác email) |
| `transcript` | **Bắt buộc** | Nội dung transcript (tối thiểu 50 ký tự) |
| `ai_model` | Không | `"gemini"` hoặc `"deepseek"` (mặc định: `"gemini"`) |
| `organizer_email` | Không | Email người tổ chức (gửi nếu không có attendees) |
| `notification_chat_id` | Không | Telegram Chat ID (bỏ qua nếu trống) |
| `sheet_id` | Không | Google Sheet ID để lưu log |

### Response (200 OK)

```json
{
  "success": true,
  "request_id": "MTG-1747008000000",
  "meeting_title": "Sprint 3 Review & Sprint 4 Planning",
  "meeting_date": "2026-05-11",
  "ai_model_used": "gemini",
  "results": {
    "action_items_count": 5,
    "decisions_count": 3,
    "topics_count": 4,
    "effectiveness_score": 8
  },
  "notifications": {
    "email_sent_to": "minh@company.vn,hoa@company.vn",
    "telegram_notified": true,
    "google_sheets_logged": true
  },
  "processed_at": "2026-05-11T10:30:00.000Z"
}
```

---

## 🤖 AI Output Format

AI sẽ trả về JSON với cấu trúc:

```json
{
  "meeting_summary": "Sprint 3 hoàn thành đúng tiến độ với các tính năng chính được giao, trừ module thanh toán còn 1 bug nhỏ...",
  "key_topics": [
    {
      "topic": "Review Sprint 3",
      "summary": "Hoa hoàn thành 100%, Tuấn còn 1 bug thanh toán...",
      "outcome": "Sprint 3 release dời sang 20/5 để QA test đủ thời gian"
    }
  ],
  "key_decisions": [
    {
      "decision": "Dời release date Sprint 3 từ 13/5 sang 20/5",
      "owner": "Nguyễn Văn Minh",
      "rationale": "Cần thêm thời gian QA test và fix bug thanh toán"
    }
  ],
  "action_items": [
    {
      "task": "Fix bug timeout module thanh toán",
      "owner": "Lê Văn Tuấn",
      "deadline": "2026-05-13",
      "priority": "high",
      "notes": "Bug xảy ra với giao dịch > 5 triệu VNĐ"
    }
  ],
  "next_steps": "Tuấn fix bug thanh toán, Trang test toàn bộ Sprint 3, chuẩn bị Sprint 4",
  "next_meeting": {
    "suggested_date": "2026-05-18",
    "agenda_preview": "Sprint 4 kickoff, review automation test plan"
  },
  "meeting_effectiveness_score": 8,
  "improvement_suggestions": "Nên chuẩn bị agenda rõ ràng trước 1 ngày..."
}
```

---

## 📱 Telegram Output Mẫu

```
📋 BIÊN BẢN CUỘC HỌP
━━━━━━━━━━━━━━━━━━━━

📌 Sprint 3 Review & Sprint 4 Planning
📅 Thứ Hai, 11 tháng 5, 2026
👥 4 người tham dự
🤖 AI: Gemini 2.0 | ⭐ 8/10

📝 Tóm tắt:
Sprint 3 hoàn thành tốt, release dời 20/5 để QA đủ thời gian...

✅ Quyết định (3):
  1. Dời release Sprint 3 sang 20/5
  2. Setup môi trường test riêng cho QA
  3. Sprint 4 bắt đầu 13/5

📌 Action Items (5):
  1. 🔴 Fix bug timeout thanh toán
     👤 Lê Văn Tuấn | 2026-05-13
  2. 🟡 Lên kế hoạch automation test
     👤 Phạm Thu Trang | 2026-05-15
  3. 🟢 Setup QA environment
     👤 Nguyễn Văn Minh | 2026-05-15

📅 Họp tiếp: 2026-05-18
━━━━━━━━━━━━━━━━━━━━
✉️ Email đã gửi cho 4 người
📊 Đã lưu Google Sheets | ID: MTG-1747008000
```

---

## 🔀 So Sánh Gemini vs DeepSeek

| Tiêu chí | Gemini 2.0 Flash | DeepSeek Chat |
|---------|-----------------|---------------|
| Tốc độ | ⚡ 2-5s | ⚡ 3-8s |
| Chất lượng tiếng Việt | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Chi phí (1M tokens) | ~$0.075 input | ~$0.14 input |
| Context window | 1M tokens | 64K tokens |
| API ổn định | ✅ Google Cloud | ✅ DeepSeek |
| JSON output | ✅ Native | ✅ json_object |
| Free tier | ✅ Có | ✅ Có |

**Khuyến nghị:**
- **Transcript ngắn < 10K ký tự**: Cả hai đều tốt → dùng Gemini (nhanh hơn)
- **Transcript dài > 50K ký tự**: Dùng Gemini (context window lớn hơn)
- **Chi phí tối ưu**: DeepSeek (rẻ hơn khi volume lớn)
- **Tiếng Việt chuẩn**: Gemini (được tối ưu tốt hơn)

---

## 🧪 Testing & Demo

### Test với pinData (không cần credentials)

Workflow có sẵn **pinData** trên node Webhook với transcript mẫu:
- Cuộc họp Sprint Review 4 người (PM, Dev x2, QA)
- Đủ nội dung: review, quyết định, action items, kế hoạch

```
1. Import workflow
2. Click "Test Workflow" → dùng pinData tự động
3. Xem kết quả từng node mà không cần webhook thật
4. Sau khi hiểu → cài credentials thật
```

### Gửi Request thật (curl)

```bash
curl -X POST https://your-n8n.com/webhook/meeting-transcript \
  -H "Content-Type: application/json" \
  -d '{
    "meeting_title": "Weekly Team Sync",
    "meeting_date": "2026-05-11",
    "attendees": ["you@company.com"],
    "transcript": "Cuộc họp thảo luận về tiến độ dự án...(tối thiểu 50 ký tự)",
    "ai_model": "gemini",
    "organizer_email": "you@company.com"
  }'
```

### Test từng node riêng lẻ

```
Node 🤖 Gemini → "Execute Node" → xem raw AI response
Node 🔍 Parse → kiểm tra JSON extraction
Node ✍️ Format → preview email HTML và Telegram
```

---

## 🔒 Security Notes

### ✅ Best Practices

| Điều | Cách làm đúng |
|------|---------------|
| API Keys | Dùng n8n Credentials, KHÔNG hardcode |
| Webhook | Thêm Basic Auth hoặc Header secret |
| Transcript | Chỉ gửi lên AI những gì cần thiết |
| Sheet ID | Không để public, phân quyền IAM |
| Telegram | Dùng bot riêng cho meeting notifications |

### Bảo vệ Webhook

Thêm Basic Auth cho webhook để tránh bị gọi bởi người lạ:
```
Node Webhook → Authentication → Basic Auth
→ Username: meeting-bot
→ Password: [tạo password mạnh]
```

### Privacy khi dùng AI

```javascript
// ✅ ĐÚNG: Gửi transcript từ cuộc họp nội bộ
// Lưu ý: Gemini/DeepSeek Free có thể dùng data để train

// Nếu transcript có thông tin nhạy cảm (tài chính, pháp lý):
// → Dùng Gemini API Paid (Enterprise) hoặc DeepSeek API
// → Hoặc cài n8n self-hosted + model local (Ollama)
```

---

## 🐛 Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|-------------|-----------|
| `Transcript quá ngắn` | Transcript < 50 chars | Gửi transcript đầy đủ hơn |
| `Lỗi parse AI response` | AI không trả JSON hợp lệ | Thử chạy lại, hoặc đổi ai_model |
| `Gemini credential error` | API key sai hoặc hết quota | Kiểm tra Google AI Studio |
| `DeepSeek 401 Unauthorized` | Header Auth sai | Kiểm tra format: `Bearer YOUR_KEY` |
| `Gmail credential error` | OAuth2 expired | Re-authenticate credentials |
| `Sheet not found` | Sheet ID sai hoặc tab sai | Kiểm tra sheet_id và tên tab "Meeting Log" |
| `Telegram chat not found` | Chat ID sai | Kiểm tra chat_id, gửi /start cho bot |
| `Timeout AI call` | Transcript quá dài | Cắt ngắn transcript (< 50K chars) |

---

## 🚀 Mở Rộng

### Tích hợp Otter.ai / Google Meet

Tự động lấy transcript từ Google Meet:
```
Google Meet kết thúc → Google Drive Trigger
→ Download transcript file
→ Gửi lên webhook này
```

### Thêm Notion Integration

Sau node "Parse Kết Quả AI", thêm:
```
HTTP Request → Notion API
→ Create page trong database "Meeting Notes"
→ Format: Notion blocks
```

### Webhook từ Zoom

```javascript
// Zoom webhook payload:
const transcriptUrl = body.payload.object.recording_files
  .find(f => f.file_type === 'TRANSCRIPT')?.download_url;
// Download và gửi lên workflow này
```

### Reminder Action Items (n8n Schedule)

```
Cron: Hàng ngày 9h sáng
→ Google Sheets: lấy action items chưa xong
→ Telegram: nhắc nhở từng người
```

### Multi-language Support

Thêm field `language` vào request để AI phân tích theo ngôn ngữ:
```json
{ "language": "en" }  // Tiếng Anh
{ "language": "vi" }  // Tiếng Việt (mặc định)
```

---

## 📁 Cấu Trúc Files

```
enterprise/11-meeting-transcript-ai/
├── workflow.json    # Workflow n8n (13 nodes)
└── GUIDE.md         # File này
```

---

## 📋 Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-05-11 | Initial release: Gemini + DeepSeek, Email + Telegram + Sheets |

---

**Tạo:** 2026-05-11
**Phiên bản:** 1.0.0
**Tác giả:** Teaching Collection - n8n Vietnam
