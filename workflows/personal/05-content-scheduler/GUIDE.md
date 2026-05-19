# 📅 Personal: Content Scheduler

## Mục tiêu
Tự động **đăng bài lên social media** theo lịch đã lên sẵn trong Google Sheets:
- Đọc content calendar từ Google Sheets
- Kiểm tra bài nào đến giờ đăng
- Format phù hợp cho từng platform (Twitter, LinkedIn, Facebook)
- Đăng bài tự động
- Update status và notify

## Đối tượng sử dụng
**Cá nhân & Businesses** - Social media managers, content creators, marketers.

## Sơ đồ luồng
```
[Schedule Trigger - Hourly Check]
         │
         ▼
[Read Content Calendar]
  (Google Sheets)
         │
         ▼
[Filter Due Posts]
  (Scheduled time reached)
         │
    ┌────┴────┐
    ▼         ▼
[IF: Has Posts?]
    │ yes     │ no
    ▼         ▼
[Switch: Platform?]  [Stop]
    │
    ├─ Twitter → Post to Twitter
    ├─ LinkedIn → Post to LinkedIn
    └─ Facebook → Post to Facebook
         │
         ▼
[Update Status to Published]
         │
         ▼
[Notify via Telegram]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Schedule Trigger | Schedule | Every hour | None |
| Read Content Calendar | Google Sheets | Read all rows | Google Sheets OAuth2 |
| Filter Due Posts | Code | Time comparison | None |
| IF: Has Posts? | IF | count > 0 | None |
| Switch: Platform? | Switch | Route by platform | None |
| Post to Twitter | Twitter | Post tweet | Twitter API |
| Post to LinkedIn | LinkedIn | Post article | LinkedIn OAuth2 |
| Post to Facebook | Facebook | Post to page | Facebook Graph API |
| Update Status | Google Sheets | Update row | Google Sheets OAuth2 |
| Notify via Telegram | Telegram | Success message | Telegram Bot Token |

## Cài đặt

### Bước 1: Tạo Google Sheets Content Calendar

| id | content | platform | scheduled_time | status | media_url |
|----|---------|----------|----------------|--------|-----------|
| 1 | Chúc buổi sáng tốt lành! #motivation | Facebook | 2026-05-05T08:00:00 | scheduled | |
| 2 | New blog post about AI trends | LinkedIn | 2026-05-05T10:00:00 | scheduled | https://... |
| 3 | Tips for productivity 🚀 | Twitter | 2026-05-05T14:00:00 | scheduled | |

**Notes:**
- `id`: Unique identifier cho mỗi post
- `content`: Nội dung bài đăng
- `platform`: `twitter`, `linkedin`, hoặc `facebook`
- `scheduled_time`: ISO format datetime
- `status`: `scheduled`, `published`, hoặc `failed`
- `media_url`: URL của image/video (optional)

**Lấy Sheet ID:**
```
URL: https://docs.google.com/spreadsheets/d/SHEET_ID/edit
                                                   ↑
                                         Copy phần này
```

### Bước 2: Chuẩn bị Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |
| **Twitter API** | https://developer.twitter.com/en/portal - Cần bearer token |
| **LinkedIn OAuth2** | https://developer.linkedin.com/ - Cần app credentials |
| **Facebook Graph API** | https://developers.facebook.com/ - Cần Page access token |
| **Telegram Bot** (Optional) | @BotFather → Create bot → Copy token |

### Bước 3: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/personal/05-content-scheduler/workflow.json`
4. Click **Import**

### Bước 4: Cấu hình

**1. Schedule Trigger:**
- Set **Rule**: `everyHour`
- Set **triggerAtMinute**: `0`
- Kiểm tra mỗi giờ xem có post nào cần đăng

**2. Read Content Calendar:**
- Set **Document ID** = Sheet ID
- Set **Sheet Name** = tên sheet

**3. Platform Nodes:**
- **Twitter:** Gán Twitter API credentials
- **LinkedIn:** Gán LinkedIn OAuth2
- **Facebook:** Gán Facebook Graph API credentials
- **Hoặc xóa nodes không dùng**

**4. Update Status:**
- Set **Document ID** = Sheet ID
- Set **Sheet Name** = tên sheet

**5. Notify via Telegram:**
- Set **Chat ID** = chat ID của bạn
- Gán Telegram credential

### Bước 5: Test

1. Thêm row mới vào Google Sheets với `scheduled_time` = 1 tiếng trước
2. Set `status` = `scheduled`
3. Click **Test Workflow**
4. Kiểm tra:
   - ✅ Bài đăng được filter đúng không?
   - ✅ Post lên platform thành công không?
   - ✅ Status được update thành `published`?
   - ✅ Telegram notification có đến không?
5. Nếu OK → **Activate** workflow

## Platform-Specific Formatting

### Twitter/X
- Max 280 characters
- Include hashtags
- Media: max 4 images

### LinkedIn
- Professional tone
- Longer content OK (up to 3,000 characters)
- Include relevant hashtags

### Facebook
- Conversational tone
- Can include links
- Media: images, videos

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Không đọc được Sheet | Sheet ID sai | Kiểm tra lại URL |
| Post không đăng | API credentials sai | Reconnect credentials |
| Status không update | Sheet ID sai hoặc id không khớp | Kiểm tra column mapping |
| Telegram không gửi | Bot token/chat_id sai | Kiểm tra credentials |

## ⚠️ Lưu ý Community Version

- ✅ **Google Sheets node** có sẵn, hoạt động tốt
- ✅ **Schedule trigger** hoạt động tốt
- ⚠️ **Twitter API** có thể cần paid tier cho full access
- ⚠️ **LinkedIn/Facebook APIs** cần app approval
- 💡 **Tip**: Bắt đầu với 1 platform trước, test kỹ, sau đó thêm platforms khác

## Mở rộng

### Thêm AI Content Generation
Tự động tạo content:
```
Schedule → OpenAI (Generate post based on topic) → Add to Sheet → Post
```

### Thêm Best Time Posting
Đăng vào giờ optimal:
```javascript
const bestTimes = {
  twitter: ['9:00', '12:00', '17:00'],
  linkedin: ['8:00', '12:00', '17:00'],
  facebook: ['13:00', '15:00', '19:00']
};
```

### Thêm Hashtag Suggestions
AI đề xuất hashtags:
```
Content → OpenAI (Suggest hashtags) → Append to content → Post
```

### Thêm Analytics Tracking
Theo dõi performance:
```
Schedule (weekly) → Fetch post metrics → Update Sheet with engagement data
```
