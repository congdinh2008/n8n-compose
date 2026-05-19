# 📝 Personal: Meeting Notes AI

## Mục tiêu
Tự động **ghi chú và tóm tắt cuộc họp**:
- Kiểm tra Google Calendar cho meetings đã kết thúc
- Nếu có recording → Transcribe + Summarize bằng AI
- Extract action items tự động
- Lưu notes và gửi cho attendees

## Đối tượng sử dụng
**Professionals** - Bất kỳ ai tham gia nhiều meetings và muốn tự động ghi chú.

## Sơ đồ luồng
```
[Schedule Trigger - Hourly]
         │
         ▼
[Check Google Calendar]
  (Meetings ended in last hour)
         │
    ┌────┴────┐
    ▼         ▼
[Has      [No
 Recording?] Recording?]
    │ yes     │
    ▼         ▼
[Download  [Send Reminder
Recording]  to Add Notes]
    │
    ▼
[Transcribe (AI Whisper)]
    │
    ▼
[Summarize (AI GPT)]
    │
    ▼
[Extract Action Items]
    │
    ├──────────┬──────────┐
    ▼          ▼          ▼
[Save to   [Email     [Create
 Notion]    Attendees]  Tasks]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Schedule Trigger | Schedule | Hourly (8 AM - 6 PM) | None |
| Check Calendar | Google Calendar | Get events | Google Calendar OAuth2 |
| Download Recording | HTTP Request | Google Meet URL | Google OAuth2 |
| Transcribe Audio | HTTP Request (OpenAI) | Whisper API | OpenAI API Key |
| Summarize | HTTP Request (OpenAI) | GPT-4 API | OpenAI API Key |
| Save to Notion | HTTP Request | Notion API | Notion Integration Token |
| Email Summary | Gmail | Vietnamese template | Gmail OAuth2 |
| Create Tasks | Todoist/Google Tasks | Action items | Todoist/Google OAuth2 |

## Cài đặt

### Bước 1: Chuẩn bị API Keys

| Service | Hướng dẫn | Cost |
|---------|-----------|------|
| **OpenAI API** | platform.openai.com → Create API key | Pay per use (~$0.01-0.10/meeting) |
| **Google Calendar OAuth2** | Settings → Credentials → Add | Free |
| **Notion Integration** | notion.so/my-integrations → Create | Free |
| **Gmail OAuth2** | Settings → Credentials → Add | Free |

### Bước 2: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/personal/08-meeting-notes/workflow.json`
4. Click **Import**

### Bước 3: Configure OpenAI API

Mở các HTTP Request nodes và thêm:
- **Header**: `Authorization: Bearer YOUR_OPENAI_KEY`
- **Whisper endpoint**: `https://api.openai.com/v1/audio/transcriptions`
- **GPT endpoint**: `https://api.openai.com/v1/chat/completions`

### Bước 4: Test

1. Schedule một meeting test (30 minutes)
2. Có recording (Google Meet record)
3. Chờ workflow chạy (hoặc trigger manually)
4. Kiểm tra:
   - ✅ Recording được download?
   - ✅ Transcript chính xác?
   - ✅ Summary đúng nội dung?
   - ✅ Action items được extract?
   - ✅ Email summary đã gửi?
5. Nếu OK → **Activate** workflow

## AI Prompts

### Transcription
```
Audio file → OpenAI Whisper API
Returns: Full transcript text
```

### Summarization
```
System: Bạn là trợ lý ghi chú cuộc họp chuyên nghiệp.
Tóm tắt cuộc họp sau bằng tiếng Việt:

{transcript}

Yêu cầu:
- Tóm tắt ngắn gọn (200-300 từ)
- Nêu rõ quyết định quan trọng
- Liệt kê action items
```

### Action Items Extraction
```
Từ transcript sau, trích xuất tất cả action items:

{transcript}

Format:
- [Person] sẽ [Action] trước [Deadline]
```

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Không download được recording | URL sai hoặc expire | Kiểm tra Google Meet URL |
| OpenAI API error | API key sai hoặc hết credit | Kiểm tra platform.openai.com |
| Transcript không chính xác | Audio chất lượng kém | Dùng microphone tốt hơn |
| Notion save error | Integration token sai | Kiểm tra permissions |

## ⚠️ Lưu ý Community Version

- ✅ **HTTP Request node** có sẵn
- ✅ **OpenAI API** hoạt động tốt (cần API key)
- ⚠️ **Recording download** - Google Meet URL expire nhanh
- 💡 **Tip**: Có thể skip recording và chỉ nhắc user add notes manually

## Mở rộng

### Thêm Real-time Transcription
Live transcription trong meeting:
```
Webhook (during meeting) → Stream to Whisper → Live notes
```

### Thêm Meeting Templates
Templates cho các loại meetings khác nhau:
```
Meeting Type → Select Template → Custom Summary Format
```

### Thêm Integration với Project Management
Auto-create tasks trong Jira/Asana:
```
Action Items → Create Jira/Asana tasks → Assign to people
```
