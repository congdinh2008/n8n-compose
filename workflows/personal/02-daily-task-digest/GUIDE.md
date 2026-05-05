# 📋 Personal: Daily Task Digest

## Mục tiêu
Tự động tạo **Morning Briefing** hàng ngày - tổng hợp tasks, meetings, và focus items vào email gửi cho bạn lúc 8:00 AM mỗi sáng.

## Đối tượng sử dụng
**Cá nhân** - Bất kỳ ai muốn có tóm tắt công việc đầu ngày để chuẩn bị tinh thần và ưu tiên tasks.

## Sơ đồ luồng
```
[Schedule Trigger - 8:00 AM]
         │
         ▼
[Fetch & Merge Tasks]
  (Todoist/Notion/Calendar)
         │
         ▼
[Format Morning Briefing]
  (Tiếng Việt, formatted)
         │
    ┌────┴────┐
    ▼         ▼
[Email]   [Telegram]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Schedule Trigger | Schedule | Daily at 8:00 AM | None |
| Fetch & Merge Tasks | Code | Mock data (cần customize) | None |
| Format Morning Briefing | Code | Tiếng Việt formatting | None |
| Send Email (Gmail) | Gmail | To = your email | Gmail OAuth2 |
| Send Telegram (Optional) | Telegram | Chat ID = yours | Telegram Bot Token |

## Cài đặt

### Bước 1: Chuẩn bị Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail OAuth2 → Connect với tài khoản Google |
| **Telegram Bot** (Optional) | Tạo bot qua @BotFather trên Telegram → Copy bot token → Add credentials |

### Bước 2: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn file: `workflows/personal/02-daily-task-digest/workflow.json`
4. Click **Import**

### Bước 3: Cấu hình

**1. Schedule Trigger:**
- Mở node "Schedule Trigger (8 AM Daily)"
- Set **Rule**: `everyDay`
- Set **triggerAtHour**: `8`
- Set **triggerAtMinute**: `0`

**2. Fetch & Merge Tasks:**
- Mở node "Fetch & Merge Tasks"
- **TODO**: Thay thế mock data bằng code lấy data từ:
  - **Todoist**: Dùng Todoist node → Get all tasks → Filter due = today
  - **Google Calendar**: Dùng Google Calendar node → Get events → Filter date = today
  - **Notion**: Dùng HTTP Request → Notion API → Query database

**3. Format Morning Briefing:**
- Mở node "Format Morning Briefing"
- Review và customize template email theo ý thích

**4. Send Email:**
- Set **To** = email của bạn
- Verify Gmail credential đã được gán

**5. Send Telegram (Optional):**
- Set **Chat ID** = chat ID của bạn (hoặc group)
- Gán Telegram credential
- **Hoặc xóa node này** nếu không dùng Telegram

### Bước 4: Test

1. Click **Test Workflow** trong n8n
2. Kiểm tra:
   - ✅ Email đã nhận được chưa?
   - ✅ Format tiếng Việt có đúng không?
   - ✅ Telegram message (nếu dùng) có đến không?
3. Nếu OK → **Activate** workflow

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Không nhận được email | Gmail credential chưa đúng | Reconnect Gmail OAuth2 trong Settings |
| Email không có dữ liệu | Mock data chưa được thay thế | Customize node "Fetch & Merge Tasks" |
| Telegram không gửi được | Bot token hoặc chat_id sai | Kiểm tra lại credentials |
| Workflow không chạy | Schedule chưa active | Bật workflow (toggle Active) |
| Lỗi timezone | Server timezone khác | Set `GENERIC_TIMEZONE=Asia/Ho_Chi_Minh` trong docker-compose |

## ⚠️ Lưu ý Community Version

- ✅ **Schedule Trigger** hoạt động tốt trong community
- ✅ **Gmail node** có sẵn, chỉ cần OAuth2
- ⚠️ **Todoist/Notion nodes** có sẵn nhưng cần API token
- ⚠️ **Google Calendar node** cần OAuth2 và enable Google Calendar API
- 💡 **Tip**: Bắt đầu với mock data, sau đó dần kết nối các apps thật

## Mở rộng

### Thêm AI Summary
Dùng OpenAI node để AI tóm tắt tasks và đưa ra lời khuyên:
```
Fetch Tasks → OpenAI (Summarize & Prioritize) → Format → Send
```

### Thêm Weather Info
Thêm node lấy thời tiết hôm nay:
```javascript
const weather = await fetch('https://api.openweathermap.org/data/2.5/weather?q=Ho+Chi+Minh&appid=YOUR_API_KEY');
// Add to briefing: "Hôm nay thời tiết: {weather.description}, {temp}°C"
```

### Multiple Recipients
Gửi briefing cho cả team:
```javascript
const recipients = ['member1@company.com', 'member2@company.com'];
// Loop qua từng recipient và gửi email riêng
```

## Google Sheets Template (Optional)

Nếu muốn lưu lịch sử briefings vào Google Sheets, thêm node **Google Sheets - Append** ở cuối:

| Column | Value |
|--------|-------|
| date | `={{ $json.date }}` |
| urgent_count | `={{ $json.summary.urgent_count }}` |
| total_tasks | `={{ $json.summary.total_tasks }}` |
| meetings | `={{ $json.summary.meetings_today }}` |
