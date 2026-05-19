# 📚 Personal: Learning Digest

## Mục tiêu
Tự động **tổng hợp content học tập** từ Reddit, HackerNews, YouTube mỗi ngày và gửi **email buổi tối** với top bài viết đáng đọc.

## Đối tượng sử dụng
**Cá nhân** - Developers, tech enthusiasts muốn cập nhật kiến thức hàng ngày.

## Sơ đồ luồng
```
[Schedule Trigger - 7:00 PM Daily]
         │
    ┌────┼────┐
    ▼    ▼    ▼
[Reddit] [HN] [YouTube]
    │    │    │
    └────┼────┘
         ▼
[Filter & Aggregate Content]
  (Keywords: AI, Python, JS, etc.)
         │
         ▼
[Format Learning Digest]
  (Tiếng Việt email)
         │
         ▼
[Send Email (Gmail)]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Schedule Trigger | Schedule | Daily at 7:00 PM | None |
| Fetch Reddit | HTTP Request | Reddit API (free) | None |
| Fetch HackerNews | HTTP Request | HN API (free) | None |
| Fetch YouTube | HTTP Request | YouTube Data API | YouTube API Key |
| Filter & Aggregate | Code | Keyword filtering | None |
| Format Digest | Code | Vietnamese template | None |
| Send Email | Gmail | To = your email | Gmail OAuth2 |

## Cài đặt

### Bước 1: Chuẩn bị Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail → Connect |
| **YouTube API Key** | Google Cloud Console → APIs & Services → Credentials → Create API Key |

### Bước 2: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/personal/06-learning-digest/workflow.json`
4. Click **Import**

### Bước 3: Cấu hình

**1. Schedule Trigger:**
- Set **Rule**: `everyDay`
- Set **triggerAtHour**: `19` (7 PM)
- Set **triggerAtMinute**: `0`

**2. Fetch YouTube:**
- Thêm API key vào Query Parameters:
  - Name: `key`
  - Value: `YOUR_YOUTUBE_API_KEY`

**3. Format Learning Digest:**
- Mở node → Set **to** = email của bạn
- Customize keywords trong Code node nếu cần

**4. Send Email:**
- Gán Gmail credential

### Bước 4: Test

1. Click **Test Workflow**
2. Kiểm tra:
   - ✅ Email có nhận được không?
   - ✅ Content có relevant không?
   - ✅ Format tiếng Việt đúng không?
3. Nếu OK → **Activate** workflow

## ⚠️ Lưu ý Community Version

- ✅ **HTTP Request node** có sẵn, hoạt động tốt
- ✅ **Reddit & HN API** free, không cần API key
- ⚠️ **YouTube API** có giới hạn 10,000 units/day
- 💡 **Tip**: Có thể bỏ YouTube node nếu không cần

## Mở rộng

### Thêm OpenAI Summary
Dùng GPT để tóm tắt từng bài viết:
```
Filter Content → OpenAI (Summarize each) → Format → Send
```

### Thêm RSS Feeds
Thêm sources từ RSS:
```
RSS Read Node → Filter → Merge with other sources
```

### Personalize Keywords
Thêm keywords phù hợp với lĩnh vực của bạn:
```javascript
const keywords = [
  'AI', 'machine learning', // Tech
  'marketing', 'SEO',       // Marketing
  'finance', 'investment'   // Finance
];
```
