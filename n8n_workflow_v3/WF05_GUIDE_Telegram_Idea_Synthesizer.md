# WF05 — Telegram AI Idea Synthesizer
## Hướng dẫn cài đặt & vận hành

> **Version:** 1.0 | **AI Model:** Gemini 2.0 Flash | **n8n:** Community 2.20+ stable  
> **File workflow:** `WF05_Telegram_Idea_Synthesizer_Gemini.json`

---

## 📐 Kiến trúc workflow

```
Telegram Message
      │
      ▼
[Telegram Trigger]
      │
      ▼
[Set: Extract Message Data]
      │
      ▼
[IF: Has Text Message?]
    ├── YES ──► [Telegram: Processing Ack] ──► [Gemini: Analyze Idea (Chain)]
    │                                                     │  ▲
    │                                          [Gemini: Flash Model] (sub-node)
    │                                                     │
    │                                          [Code: Parse AI Response]
    │                                                     │
    │                                          [Sheets: Log to Google Sheet]
    │                                                     │
    │                                          [Telegram: Send AI Analysis]
    │                                                     │
    │                                          [Telegram: Send Full Summary]
    │
    └── NO ──► [Telegram: Reply No Text Warning]
```

### Luồng dữ liệu
| Bước | Node | Mục đích |
|------|------|----------|
| 1 | Telegram Trigger | Nhận tin nhắn từ user qua webhook |
| 2 | Set: Extract | Chuẩn hoá dữ liệu: chat_id, user_message, timestamp |
| 3 | IF: Has Text | Lọc chỉ xử lý tin nhắn text |
| 4 | Telegram Ack | Gửi "đang xử lý..." để UX tốt hơn |
| 5 | Gemini Chain | Phân tích ý tưởng, trả JSON có cấu trúc |
| 6 | Code: Parse | Parse JSON, handle lỗi, merge context |
| 7 | Google Sheets | Lưu ý tưởng + phân tích vào spreadsheet |
| 8 | Telegram Reply 1 | Gửi tóm tắt nhanh từ AI |
| 9 | Telegram Reply 2 | Gửi chi tiết đầy đủ (rating, next steps) |

---

## 🔧 Yêu cầu trước khi cài đặt

- [x] **n8n Community** đang chạy (bản 2.20+ stable)
- [x] **Telegram Bot** — tạo qua [@BotFather](https://t.me/BotFather)
- [x] **Google Cloud Project** — bật Google Sheets API + Gemini API
- [x] **Google Sheets** — tạo spreadsheet với sheet tên `Ideas Log`

---

## 🤖 Bước 1: Tạo Telegram Bot

### 1.1 Tạo bot với BotFather
1. Mở Telegram, tìm **@BotFather**
2. Gõ `/newbot`
3. Nhập tên bot: `My Idea Synthesizer Bot`
4. Nhập username (phải kết thúc bằng `bot`): `myideasynthesizer_bot`
5. Lưu lại **Bot Token** nhận được (dạng: `123456789:ABCDefGHI...`)

### 1.2 Lấy Chat ID của bạn
1. Gửi 1 tin nhắn bất kỳ cho bot vừa tạo
2. Mở browser, truy cập:
   ```
   https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   ```
3. Tìm trường `"chat":{"id": 123456789}` — đây là **Chat ID** của bạn

### 1.3 Thêm Telegram credential vào n8n
1. **n8n** → **Credentials** → **New Credential**
2. Tìm **Telegram API**
3. Điền **Access Token**: Bot token từ BotFather
4. Lưu tên: `Telegram Bot`

---

## 📊 Bước 2: Tạo Google Sheet

### 2.1 Cấu trúc Sheet bắt buộc
Tạo Google Sheets mới, đặt tên sheet tab là **`Ideas Log`**.

Tạo **hàng đầu tiên** với các cột header:

| A | B | C | D | E | F | G | H | I | J | K | L | M |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Timestamp | Date | Username | User Name | Original Idea | Category | Summary | Key Points | Suggestions | Risks | Next Steps | AI Rating | Status |

### 2.2 Lấy Google Sheet ID
Từ URL: `https://docs.google.com/spreadsheets/d/`**`[SHEET_ID_Ở_ĐÂY]`**`/edit`

### 2.3 Thêm Google Sheets credential vào n8n
**Credentials** → **New** → **Google Sheets OAuth2 API** → Connect Google Account

---

## 🧠 Bước 3: Cài đặt Gemini API

1. Truy cập [Google AI Studio](https://aistudio.google.com/app/apikey)
2. **Create API Key** → Copy key
3. **n8n Credentials** → **New** → **Google Gemini(PaLm) API** → Điền API Key
4. Lưu tên: `Google Gemini - Class Shared`

> 💡 **Model mặc định:** `models/gemini-2.0-flash` — nhanh, chi phí thấp.

---

## 📥 Bước 4: Import & Cấu hình Workflow

### 4.1 Import
1. **n8n** → **Workflows** → **Import from File**
2. Chọn file `WF05_Telegram_Idea_Synthesizer_Gemini.json`

### 4.2 Cập nhật Credentials cho từng node

| Node | Credential cần gán |
|------|-------------------|
| Telegram Trigger | `Telegram Bot` |
| Telegram: Send Processing Ack | `Telegram Bot` |
| Telegram: Send AI Analysis | `Telegram Bot` |
| Telegram: Send Full Summary | `Telegram Bot` |
| Telegram: Reply No Text Warning | `Telegram Bot` |
| Gemini: Flash Model | `Google Gemini - Class Shared` |
| Sheets: Log Idea | `Google Sheets Personal` |

### 4.3 Cập nhật Google Sheet ID
Click node **Sheets: Log Idea to Google Sheet** → Trường **Document** → Nhập Sheet ID

---

## 🔗 Bước 5: Đăng ký Webhook Telegram

Workflow dùng Webhook (real-time) thay vì polling.

### Cách tự động (khuyên dùng)
1. **Activate workflow** (bật toggle Active)
2. n8n tự set webhook → Test bằng cách gửi tin nhắn

### Cách thủ công
```bash
curl -X POST "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://your-n8n-url/webhook/telegram-idea-bot-webhook"}'
```

> ⚠️ n8n **phải có Public HTTPS URL**. Dự án này đang dùng Cloudflare Tunnel — URL từ terminal `cloudflared tunnel` chính là URL cần dùng.

---

## 🧪 Bước 6: Test Workflow

### Test Case 1 — Ý tưởng kinh doanh
```
Tôi muốn mở một cửa hàng cà phê kết hợp không gian làm việc co-working ở quận 1 TPHCM, 
target freelancer và startup. Ngân sách khoảng 500 triệu.
```

### Test Case 2 — Ý tưởng công nghệ
```
Xây dựng app giúp học sinh ôn thi đại học bằng AI, tạo đề thi thử cá nhân hoá 
dựa trên điểm yếu của từng người.
```

**Kết quả mong đợi mỗi test:**
- ✅ Bot reply "đang phân tích..." ngay lập tức
- ✅ Bot gửi phân tích AI với category, rating, suggestions
- ✅ Bot gửi chi tiết key points + next steps  
- ✅ Dòng mới xuất hiện trong Google Sheet

---

## 🗂️ Cấu trúc dữ liệu Google Sheet

| Cột | Ví dụ | Mô tả |
|-----|-------|-------|
| Timestamp | `2026-05-13 20:15:00` | Thời gian nhận |
| Date | `13/05/2026` | Ngày (dễ filter) |
| Username | `@john_doe` | Telegram username |
| Original Idea | `Mở cà phê...` | Nội dung gốc |
| Category | `Kinh doanh` | AI phân loại |
| Summary | `Chuỗi cà phê kết hợp...` | Tóm tắt AI |
| Key Points | `Thị trường tiềm năng\|Chi phí cao` | Pipe-separated |
| Suggestions | `Nghiên cứu vị trí\|Làm MVP` | Pipe-separated |
| Risks | `Cạnh tranh cao\|Chi phí mặt bằng` | Pipe-separated |
| Next Steps | `Khảo sát 5 địa điểm\|...` | Pipe-separated |
| AI Rating | `7` | 1-10 |
| Status | `New` | Cập nhật theo dõi thủ công |

---

## 🔄 Tuỳ chỉnh & Mở rộng

### Đổi AI Model
Trong node **Gemini: Flash Model**, thay `modelName`:
- `models/gemini-2.0-flash` — Mặc định, nhanh & rẻ
- `models/gemini-1.5-pro` — Chất lượng cao hơn

### Giới hạn chỉ 1 user
Thêm IF node sau **Set: Extract** để check:
```javascript
$json.username === 'your_telegram_username'
```

### Tổng hợp ý tưởng hàng tuần tự động
Thêm **Schedule Trigger** (mỗi thứ Hai) → đọc Sheet → Gemini tóm tắt → gửi Telegram.

---

## 🐛 Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân | Giải pháp |
|-----|-------------|-----------|
| Webhook không nhận tin nhắn | n8n không có Public URL | Kiểm tra Cloudflare Tunnel đang chạy |
| `Cannot read property 'text'` | Update type khác (sticker, file) | IF node sẽ lọc — đảm bảo chọn đúng "message" |
| Google Sheets "Unable to parse range" | Sai tên sheet tab | Đổi tên tab thành `Ideas Log` |
| JSON parse failed | Gemini trả markdown wrapper | Code node đã handle, kiểm tra execution log |
| Telegram "message too long" | AI reply > 4096 ký tự | Prompt đã giới hạn 500 ký tự cho telegram_reply |

---

## 📝 Ghi chú kỹ thuật

### Node versions (n8n 2.20+ stable)
| Node | TypeVersion |
|------|-------------|
| `telegramTrigger` | `1.1` |
| `set` | `3.4` |
| `if` | `2` |
| `googleSheets` | `4.5` |
| `chainLlm` (Langchain) | `1.5` |
| `lmChatGoogleGemini` | `1` |

### LLM Chain Pattern
`chainLlm` là root node, `lmChatGoogleGemini` kết nối qua port `ai_languageModel` — đây là pattern chuẩn của n8n Langchain. **Không nối qua `main` port.**

---

*VTI Academy — AIA-SME-2026 · Buổi 6 · Telegram AI Integration*
