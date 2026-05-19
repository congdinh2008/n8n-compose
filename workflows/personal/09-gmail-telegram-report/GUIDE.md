# 📧 Gmail → Telegram Daily Report

> **Workflow tự động báo cáo email sáng 7h, phân loại thông minh, dọn dẹp spam**
> **Phiên bản:** 4 versions (Basic → Standard → AI Pro → DeepSeek)
> **Cập nhật:** 2026-05-11

---

## 🎯 Mục tiêu

Mỗi sáng 7:00, workflow tự động:
1. **Lấy email** chưa đọc từ Gmail (24h qua)
2. **Phân loại** email theo mức độ quan trọng
3. **Gửi báo cáo** tổng hợp lên Telegram
4. **Dọn dẹp** email spam/quảng cáo tự động

---

## 👥 Đối tượng sử dụng

| Version | Đối tượng | Kỹ năng cần có |
|---------|-----------|----------------|
| V1 Basic | Người mới học n8n | Không cần |
| V2 Standard | Intermediate | Biết cơ bản n8n |
| V3 AI Pro | Advanced/Production | Hiểu API + AI |
| V4 DeepSeek | Advanced/Production | Hiểu OpenAI-compat API |

---

## 📊 So sánh 4 phiên bản

| Feature | V1 Basic | V2 Standard | V3 AI Pro | V4 DeepSeek |
|---------|----------|-------------|-----------|-------------|
| Trigger 7h sáng | ✅ | ✅ | ✅ | ✅ |
| Lấy email Gmail | ✅ | ✅ | ✅ | ✅ |
| Gửi Telegram | ✅ | ✅ | ✅ | ✅ |
| Phân loại email | ❌ | ✅ Rule-based | ✅ AI + Rules | ✅ AI + Rules |
| Báo cáo có thống kê | ❌ | ✅ | ✅ Chi tiết | ✅ + Token cost |
| Dọn email spam | ❌ | ✅ | ✅ Thông minh | ✅ Thông minh |
| Phân tích AI | ❌ | ❌ | ✅ Gemini | ✅ DeepSeek |
| Lý do phân loại | ❌ | ❌ | ✅ | ✅ |
| Số nodes | 4 | 8 | 13 | 13 |
| Thời gian setup | 15 phút | 30 phút | 60 phút | 45 phút |
| Độ khó | ⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

---

## 🗺️ Sơ đồ luồng

### V1 Basic (4 nodes)
```
[⏰ Schedule 7h]
       │
       ▼
[📬 Gmail: Lấy email unread]
       │
       ▼
[📝 Code: Tạo báo cáo đơn giản]
       │
       ▼
[📱 Telegram: Gửi tin nhắn]
```

### V2 Standard (8 nodes)
```
[⏰ Schedule 7h]
       │
       ▼
[📬 Gmail: Lấy 100 email]
       │
       ▼
[🏷️ Code: Phân loại (keywords)]
       │
       ▼
[📊 Code: Tạo báo cáo chi tiết]
      ┌┴──────────────────┐
      ▼                   ▼
[📱 Telegram]     [IF: Có Spam?]
                          │ Yes
                          ▼
                 [🗂️ Chuẩn bị IDs]
                          │
                          ▼
                  [🗑️ Gmail: Trash]
                          │
                          ▼
                   [✅ Log Done]
```

### V3 AI Pro (13 nodes)
```
[⏰ Schedule 7h]
       │
       ▼
[📬 Gmail: Lấy 100 email]
       │
       ▼
[🔍 Pre-classify (Rules)]
       │
       ▼
[🤖 Chuẩn bị AI Prompt]
       │
       ▼
[IF: Cần gọi AI?]
   │ No              │ Yes
   ▼                 ▼
[Bỏ qua AI]   [🧠 Gemini API Call]
   │                 │
   └────────┬────────┘
            ▼
    [🔗 Kết hợp kết quả]
            │
            ▼
    [📊 Tạo báo cáo AI]
          ┌─┴────────────────┐
          ▼                  ▼
    [📱 Telegram]    [🧹 Dọn dẹp]
                            │
                     [IF: Trash/Archive?]
                       ┌────┴────┐
                       ▼         ▼
                  [🗑️ Trash]  [📁 Archive]
                       └────┬────┘
                            ▼
                     [✅ Log Done]
```

### V4 DeepSeek (13 nodes - tương tự V3 nhưng thay AI engine)
```
[⏰ Schedule 7h]
       │
       ▼
[📬 Gmail: Lấy 100 email]
       │
       ▼
[🔍 Pre-classify (Rules)]
       │
       ▼
[🤖 Chuẩn bị DeepSeek Prompt]  ← system/user message format
       │
       ▼
[IF: Cần Gọi DeepSeek?]
   │ No              │ Yes
   ▼                 ▼
[Bỏ qua AI]   [🔵 DeepSeek API Call]   ← OpenAI-compatible
   │                 │                     endpoint: api.deepseek.com
   └────────┬────────┘
            ▼
    [🔗 Parse DeepSeek Result]  ← choices[0].message.content
            │
            ▼
    [📊 Tạo báo cáo + Token cost]
          ┌─┴────────────────┐
          ▼                  ▼
    [📱 Telegram]    [🧹 Dọn dẹp]
                            │
                     [IF: Trash/Archive?]
                       ┌────┴────┐
                       ▼         ▼
                  [🗑️ Trash]  [📁 Archive]
                       └────┬────┘
                            ▼
                     [✅ Log Done]
```

**Điểm khác biệt V4 so với V3:**
| Điểm | V3 Gemini | V4 DeepSeek |
|------|-----------|-------------|
| API Endpoint | `generativelanguage.googleapis.com` | `api.deepseek.com/v1` |
| Auth | HTTP Query `?key=` | HTTP Header `Authorization: Bearer` |
| Request format | Google format (contents/parts) | OpenAI format (messages) |
| Response parse | `candidates[0].content.parts[0].text` | `choices[0].message.content` |
| Token tracking | ❌ | ✅ Hiện thị trong báo cáo |
| Tiếng Việt | Tốt | **Tốt hơn** |

---

## 🔑 Credentials cần chuẩn bị

### 1. Gmail OAuth2

**Bước thiết lập:**
1. Vào **Google Cloud Console** → tạo project mới
2. **APIs & Services** → **Enable APIs** → bật **Gmail API**
3. **OAuth consent screen** → chọn Internal (dùng nội bộ)
4. **Credentials** → **Create OAuth 2.0 Client ID** → Desktop App
5. Download JSON, lưu `client_id` và `client_secret`
6. Trong n8n: **Settings** → **Credentials** → **Add** → tìm "Gmail OAuth2"
7. Nhập client_id, client_secret → Click **Connect** → đăng nhập Google

### 2. Telegram Bot Token

**Bước thiết lập:**
1. Mở Telegram → tìm **@BotFather**
2. Gõ `/newbot` → đặt tên → đặt username (kết thúc bằng `bot`)
3. Nhận **Bot Token** (dạng: `1234567890:ABCdef...`)
4. Lấy **Chat ID**: nhắn tin cho bot → truy cập `https://api.telegram.org/bot{TOKEN}/getUpdates`
5. Trong n8n: **Settings** → **Credentials** → **Add** → tìm "Telegram"
6. Nhập Bot Token → Save

### 3. Gemini API Key (chỉ V3)


> **⚠️ SECURITY NOTE cho giảng dạy:**
> - **KHÔNG bao giờ** hardcode API key trực tiếp vào node parameters
> - **LUÔN** dùng n8n Credentials để lưu API key
> - n8n mã hóa credentials trong database (AES-256)
> - Trong production: dùng environment variables hoặc secret manager

**Bước thiết lập Gemini API:**
1. Truy cập **Google AI Studio**: https://aistudio.google.com
2. **Get API Key** → tạo key mới
3. Trong n8n: **Settings** → **Credentials** → **Add** → "HTTP Query Auth"
4. Name: `Gemini API Key`, Param Name: `key`, Value: `YOUR_API_KEY`
5. URL trong node: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`

### 4. DeepSeek API Key (chỉ V4)

> **⚠️ SECURITY NOTE cho giảng dạy:**
> DeepSeek dùng **OpenAI-compatible API** — dùng HTTP Header Auth với `Authorization: Bearer YOUR_KEY`.
> **KHÔNG** nhúng API key vào URL hoặc body. Dùng n8n Credential để mã hóa.

**Bước thiết lập DeepSeek API:**
1. Đăng ký tại **DeepSeek Platform**: https://platform.deepseek.com
2. Nạp credit (tối thiểu $5) → **API Keys** → Create new key
3. Trong n8n: **Settings** → **Credentials** → **Add** → "HTTP Header Auth"
4. Name: `DeepSeek API Key (Bearer)`, Header Name: `Authorization`, Value: `Bearer sk-your-key-here`
5. Chọn credential trong node `🔵 Gọi DeepSeek API`

**So sánh chi phí (tham khảo cho lớp học):**

| Model | Input | Output | Phù hợp |
|-------|-------|--------|----------|
| `deepseek-chat` | $0.14/1M | $0.28/1M | Daily report (rẻ) |
| `deepseek-reasoner` | $0.55/1M | $2.19/1M | Phân tích phức tạp |
| Gemini 1.5 Flash | Free tier | Free tier | Demo/học tập |

> 💡 **Cho lớp học:** Dùng `deepseek-chat` - xử lý 100 email/ngày tốn ~$0.001/lần chạy

---

## 🛠️ Cài đặt từng phiên bản

### V1 Basic - Setup 15 phút

```
workflows/personal/09-gmail-telegram-report/v1-basic/workflow.json
```

**Bước 1:** Import workflow
```
n8n Dashboard → Add Workflow → Import from File → chọn v1-basic/workflow.json
```

**Bước 2:** Cài credentials
- Mở node `📬 Lấy Email Chưa Đọc` → chọn Gmail OAuth2 credential
- Mở node `📱 Gửi Telegram` → chọn Telegram credential

**Bước 3:** Cài biến TELEGRAM_CHAT_ID
```
Settings → Variables → Add Variable
Name: TELEGRAM_CHAT_ID
Value: [chat_id của bạn, ví dụ: 123456789]
```

**Bước 4:** Test
1. Click **"Test Workflow"** (nút tam giác)
2. Xem kết quả từng node
3. Kiểm tra Telegram nhận được tin

**Bước 5:** Activate
- Toggle **Active** (góc trên phải) → ON

---

### V2 Standard - Setup 30 phút

```
workflows/personal/09-gmail-telegram-report/v2-standard/workflow.json
```

Thực hiện tương tự V1, thêm:

**Tùy chỉnh VIP Senders** (trong node `🏷️ Phân Loại Email`):
```javascript
// Thay đổi danh sách này:
const VIP_SENDERS = [
  'boss@yourcompany.com',
  'manager@yourcompany.com',
  'important-client@partner.com'
];
```

**Tùy chỉnh Spam domains:**
```javascript
const SPAM_DOMAINS = [
  'shopee.vn', 'lazada.vn',  // thêm domain spam của bạn
];
```

> ⚠️ **CẢNH BÁO**: V2 tự động xóa spam vào Thùng rác. Test kỹ trước khi Activate!

---

### V3 AI Pro - Setup 60 phút

```
workflows/personal/09-gmail-telegram-report/v3-ai-pro/workflow.json
```

Thực hiện tương tự V2, thêm:

**Cài Gemini API credential** (xem hướng dẫn ở trên)

**Mở node `🧠 Gọi Gemini API`** → chọn credential "Gemini API Key"

**Tùy chỉnh AI Prompt** (trong node `🤖 Chuẩn Bị AI Prompt`):
```javascript
// Thêm context về bản thân để AI phân loại chính xác hơn:
const prompt = `Bạn là trợ lý email của [Tên bạn].
Tôi làm [nghề nghiệp] tại [công ty].
VIP contacts: [tên sếp, khách hàng quan trọng]
...`
```

---

### V4 DeepSeek - Setup 45 phút

```
workflows/personal/09-gmail-telegram-report/v4-deepseek/workflow.json
```

Thực hiện tương tự V3, **thay Gemini bằng DeepSeek**:

**Bước 1:** Import workflow `v4-deepseek/workflow.json`

**Bước 2:** Cài DeepSeek credential
```
Settings → Credentials → Add → "HTTP Header Auth"
Name: DeepSeek API Key (Bearer)
Header Name: Authorization  
Value: Bearer sk-xxxxxxxxxxxxxxxx
```

**Bước 3:** Mở node `🔵 Gọi DeepSeek API` → chọn credential vừa tạo

**Bước 4:** (Tùy chọn) Đổi model trong jsonBody:
```json
// deepseek-chat: rẻ nhất, đủ dùng cho email
"model": "deepseek-chat"

// deepseek-reasoner: suy luận sâu hơn, chậm hơn
"model": "deepseek-reasoner"
```

**Bước 5:** Test với pinData → Activate

> 💡 **Tip cho lớp học - So sánh trực tiếp V3 vs V4:**
> Import cả 2 workflow → chạy song song với cùng pinData → so sánh kết quả phân loại và token cost

---

## 🧪 Test & Demo Config

### Mock Data (pinData) cho giảng dạy

Cả 4 workflow đều có **pinData** sẵn trên node Gmail để test mà **không cần kết nối Gmail thật**:

```
V1: 5 email demo (boss, newsletter, shopee, client, github)
V2: 6 email demo (đa dạng categories)
V3: 6 email demo (CEO, client, dev-bug, medium, shopee, mom)
V4: 6 email demo (giống V3 - cùng data để so sánh AI output)
```

**Cách dùng pinData trong lớp:**
1. Import workflow
2. Click **"Test Workflow"** → workflow dùng pinData thay vì Gmail thật
3. Học sinh thấy kết quả ngay mà không cần credential
4. **Sau khi hiểu** → xóa pinData → cài credential thật

### Test từng node

```javascript
// Test Schedule Trigger (chạy ngay không cần đợi 7h):
// Click node ⏰ → "Execute Node"

// Test Gmail node với filter:
// q = "is:unread newer_than:1d" → email 24h qua chưa đọc
// q = "is:unread from:boss@company.com" → từ sếp
// q = "is:unread subject:urgent" → có chữ urgent

// Test Telegram (gửi thử):
// Dùng test message: "Test from n8n 🤖"
```

### Cron Expression tham khảo

```
7h sáng hàng ngày:     0 7 * * *
8h30 sáng thứ 2-6:     30 8 * * 1-5
7h sáng + 12h trưa:    0 7,12 * * *
Mỗi 3 tiếng:           0 */3 * * *
```

---

## 📱 Kết quả Telegram mẫu

### V1 Output:
```
📧 Báo Cáo Email Sáng
📅 Chủ nhật, 11 tháng 5, 2026

📊 Tổng chưa đọc: 5 email

1. Q2 Report - Cần review
   📤 boss@company.com

2. Daily Digest: Top stories
   📤 newsletter@medium.com

3. Flash Sale 50% hôm nay!
   📤 Shopee
...
```

### V2 Output:
```
📧 BÁO CÁO EMAIL SÁNG NAY
📅 Chủ nhật, 11 tháng 5, 2026

📊 Thống kê:
• ⭐ Quan trọng: 2
• 📥 Bình thường: 1  
• 📰 Newsletter: 1
• 🏷️ Khuyến mãi: 1
• 🗑️ Spam: 1
• 📨 Tổng cộng: 6 email

⭐ QUAN TRỌNG - Cần xử lý:
  1. Q2 Report - Cần review...
     📤 boss@company.com
  2. Proposal - cần phản hồi gấp
     📤 client@startup.vn
...
```

### V3 AI Output:
```
🤖 BÁO CÁO EMAIL AI - SÁNG NAY
📅 Chủ nhật, 11 tháng 5, 2026
━━━━━━━━━━━━━━━━━━━━━━

📊 Thống kê toàn bộ:
• ⭐ Quan trọng: 2 email
• 💼 Công việc: 2 email
• 👤 Cá nhân: 1 email
• 📰 Newsletter: 1 email
• 🏷️ Khuyến mãi: 1 email
• 🗑️ Spam: 1 email
• 📨 Tổng: 8 email

🚨 CẦN XỬ LÝ NGAY:
  1. Họp board Q2 - Cần confirm lịch (Họp quan trọng, cần confirm)
     📤 CEO 🤖
  2. Contract renewal - cần ký trước 30/5 (Deadline ký HĐ)
     📤 Client VIP 🤖
━━━━━━━━━━━━━━━━━━━━━━

⭐ QUAN TRỌNG: ...
💼 CÔNG VIỆC: ...

🧹 Tự động dọn: 2 email (spam + promo)
🤖 Phân tích bởi Gemini AI
```

### V4 DeepSeek Output:
```
🔵 BÁO CÁO EMAIL - DEEPSEEK AI
📅 Chủ nhật, 11 tháng 5, 2026
━━━━━━━━━━━━━━━━━━━━━━

📊 Thống kê:
• ⭐ Quan trọng: 2
• 💼 Công việc: 1
• 👤 Cá nhân: 1
• 📰 Newsletter: 0
• 🏷️ Khuyến mãi: 1
• 🗑️ Spam: 1
• 📨 Tổng: 6 email

🚨 CẦN XỬ LÝ NGAY:
  1. Họp board Q2 - Cần confirm lịch (Lịch họp quan trọng)
     📤 CEO 🔵
  2. Contract renewal - cần ký trước 30/5 (Deadline hợp đồng)
     📤 Client VIP 🔵
━━━━━━━━━━━━━━━━━━━━━━

⭐ QUAN TRỌNG: ...
💼 CÔNG VIỆC: ...
👤 CÁ NHÂN: ...

━━━━━━━━━━━━━━━━━━━━━━
🧹 Tự động dọn: 2 email
🔵 Phân tích bởi DeepSeek
💰 Token: 847 (~$0.00019)
```

> 🔵 = phân loại bởi DeepSeek AI | ⚡ = phân loại bởi rule-based

---

## 🔒 Security Notes (Cho giảng dạy)

> **QUAN TRỌNG khi dạy về workflow có AI:**

### ✅ Best Practices

| Điều | Cách làm đúng |
|------|---------------|
| API Keys | Dùng n8n Credentials, KHÔNG hardcode |
| Gmail Access | Dùng OAuth2, KHÔNG dùng password |
| Email Content | Chỉ gửi subject + snippet lên AI, không gửi full body |
| Spam Filter | Test kỹ với pinData trước khi bật production |
| Bot Token | Dùng bot riêng, không dùng bot production |

### ❌ Tránh những lỗi này

```javascript
// ❌ SAI - Hardcode API key trong URL
url: "https://api.example.com/chat?key=sk-abc123def456..."

// ✅ ĐÚNG - Dùng credential
// Node → Credentials → chọn credential đã tạo

// ❌ SAI - Gửi toàn bộ email body lên AI (privacy risk)
const body = email.fullBody; // Có thể chứa thông tin nhạy cảm

// ✅ ĐÚNG - Chỉ gửi subject và snippet
const snippet = email.snippet.substring(0, 200);
```

### 🔐 Privacy khi dùng AI

Khi gửi email cho Gemini/OpenAI:
- **Nên**: Subject + Sender + Snippet (150-200 ký tự đầu)
- **Không nên**: Full email body, attachments, email cá nhân/y tế
- **Lưu ý**: Gemini Free tier có thể dùng data để train model → dùng Gemini API Pro cho production

---

## 🐛 Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|-------------|-----------|
| `Gmail credential error` | OAuth2 expired | Re-authenticate: click credential → Reconnect |
| `Telegram: chat not found` | Chat ID sai | Kiểm tra lại chat_id, thêm /start với bot |
| `No emails returned` | Filter quá strict | Thử `q = "is:unread"` không có `newer_than` |
| `AI response error` | API key hết quota | Kiểm tra Gemini Console, dùng Flash model |
| `DeepSeek 402 error` | Hết credit | Nạp thêm tại platform.deepseek.com |
| `DeepSeek JSON parse fail` | Model trả text lẫn JSON | Đã có fallback trong code, kiểm tra log |
| `Spam được xóa nhầm` | Filter quá rộng | Chỉnh SPAM_PATTERNS, test với pinData trước |
| `Workflow không chạy 7h` | Timezone sai | Settings → Timezone → Asia/Ho_Chi_Minh |
| `Expression error` | Workflow không active | Khi test, dùng "Test Workflow" không cần active |

---

## 🚀 Mở rộng (Cho học viên nâng cao)

### Thêm Google Sheets Log
```
Node: Google Sheets → Append Row
Sheet: Email Report Log
Columns: date, total, important, spam_cleaned
```

### Thêm Email Quick Reply (V4)
```
Telegram → nhận lệnh /reply → Gmail → gửi reply email
```

### Thêm Weekly Summary
```
Trigger: Thứ 2 hàng tuần, 7h30
Kết hợp với Google Sheets log → tổng kết tuần
```

### Tích hợp Calendar
```
Gmail: detect email có "meeting/họp/lịch" → tạo sự kiện Google Calendar
```

---

## 📁 Files

```
09-gmail-telegram-report/
├── GUIDE.md                    # File này
├── v1-basic/
│   └── workflow.json           # 4 nodes, ⭐ beginner
├── v2-standard/
│   └── workflow.json           # 8 nodes, ⭐⭐ intermediate
├── v3-ai-pro/
│   └── workflow.json           # 13 nodes, ⭐⭐⭐⭐ Gemini AI
└── v4-deepseek/
    └── workflow.json           # 13 nodes, ⭐⭐⭐ DeepSeek AI
```

---

**Tạo:** 2026-05-11  
**Phiên bản:** 1.0.0  
**Tác giả:** Teaching Collection - n8n Vietnam
