# 📋 Personal: Content Scheduler

## Mục tiêu
Tự động hóa **lên lịch và đăng bài** lên mạng xã hội:
- Đọc content calendar từ Google Sheets
- Lọc posts đã đến giờ đăng
- Format content cho từng platform (Twitter, LinkedIn)
- Đăng bài tự động
- Update status trong Google Sheets

## Đối tượng sử dụng
**Cá nhân & Doanh nghiệp** - Social media managers, content creators, marketing teams.

## Sơ đồ luồng
```
[Schedule Trigger (Check Hourly)]
         │
         ▼
[Read Content Calendar (Google Sheets)]
         │
         ▼
[Filter Due Posts (scheduled_time <= now)]
         │
         ▼
[IF: Has Posts to Publish?]
    │ true
    ├──────────────┐
    ▼              ▼
[IF: Twitter?]  [IF: LinkedIn?]
    │              │
    ▼              ▼
[Format        [Format
 Twitter]      LinkedIn]
    │              │
    ▼              ▼
[Post to       [Post to
 Twitter/X]    LinkedIn]
    │              │
    └──────┬───────┘
           ▼
[Update Google Sheets (Published)]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Schedule Trigger | Schedule | Check hourly | None |
| Read Content Calendar | Google Sheets | Read approved posts | Google Sheets OAuth2 |
| Filter Due Posts | Code | Filter by scheduled_time | None |
| IF: Has Posts? | IF | Check count > 0 | None |
| IF: Twitter/LinkedIn | IF | Route by platform | None |
| Format Twitter | Code | Max 280 chars, hashtags | None |
| Format LinkedIn | Code | Professional format | None |
| Post to Twitter/X | Twitter | Post tweet | Twitter OAuth2 |
| Post to LinkedIn | LinkedIn | Post update | LinkedIn OAuth2 |
| Update Google Sheets | Google Sheets | Update status | Google Sheets OAuth2 |

## Cài đặt

### Bước 1: Chuẩn bị Google Sheets Content Calendar

Tạo Google Sheet với các columns:

| platform | content | media_url | scheduled_time | status | hashtags | post_url | published_at |
|----------|---------|-----------|----------------|--------|----------|----------|--------------|
| Twitter | Content here... | https://img.url | 2026-05-05 10:00 | approved | #tech,#ai | | |
| LinkedIn | Content here... | https://img.url | 2026-05-05 14:00 | approved | #business | | |

**Status values:**
- `draft` - Đang soạn, chưa đăng
- `review` - Đang chờ duyệt
- `approved` - Đã duyệt, chờ đăng
- `published` - Đã đăng
- `failed` - Lỗi khi đăng

### Bước 2: Cấu hình Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |
| **Twitter OAuth2** | Settings → Credentials → Add → Twitter → Connect |
| **LinkedIn OAuth2** | Settings → Credentials → Add → LinkedIn → Connect |

### Bước 3: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/personal/05-content-scheduler/workflow.json`
4. Click **Import**

### Bước 4: Cấu hình Nodes

**1. Schedule Trigger:**
- Set để check hourly hoặc every 30 minutes tùy nhu cầu

**2. Read Content Calendar:**
- Set **Document ID** = Sheet ID
- Set **Sheet Name** = tên sheet
- Filter: status = 'approved'

**3. Format Twitter/LinkedIn:**
- Review và customize formatting logic
- Twitter: max 280 chars
- LinkedIn: professional tone, line breaks

**4. Post to Platforms:**
- Verify credentials đã được gán
- Test với 1 post trước khi schedule thật

**5. Update Google Sheets:**
- Set **Document ID** = Sheet ID
- Set **Sheet Name** = tên sheet
- Update status = 'published', published_at = now

### Bước 5: Test

**1. Thêm post test vào Google Sheets:**
```
platform: Twitter
content: Test post từ n8n automation
scheduled_time: 2026-05-05 10:00 (thời gian trong quá khứ)
status: approved
hashtags: test,automation
```

**2. Chạy workflow:**
- Click **Test Workflow** hoặc đợi schedule trigger

**3. Kiểm tra:**
- ✅ Post đã lên Twitter/LinkedIn chưa?
- ✅ Google Sheets đã update status?
- ✅ Format content đúng không?

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Không có posts nào | scheduled_time chưa đến hoặc status khác 'approved' | Kiểm tra sheet data |
| Twitter post fail | Character limit vượt 280 | Kiểm tra Format Twitter node |
| Credential expired | OAuth2 token hết hạn | Reconnect credentials |
| Post bị duplicate | Schedule chạy quá nhanh | Tăng interval hoặc add unique check |

## ⚠️ Lưu ý Community Version

- ✅ **Twitter/LinkedIn nodes** có sẵn
- ✅ **Google Sheets node** hoạt động tốt
- ⚠️ **OAuth2 credentials** cần reconnect định kỳ
- ⚠️ **Twitter API v2** có rate limits (300 requests/15min)
- 💡 **Tip**: Có thể dùng HTTP Request node thay cho Twitter/LinkedIn nodes nếu cần custom behavior

## Mở rộng

### Thêm Facebook/Instagram
Thêm branches cho các platforms khác:
```
IF: Facebook? → Format Facebook → Post to Facebook
IF: Instagram? → Format Instagram → Post to Instagram
```

### Thêm Content Approval Workflow
Tạo workflow riêng để approve content:
```
New Row in Sheets → Notify Manager (Slack)
                         │
                         ▼
                    Manager approves
                         │
                         ▼
                    Update status = 'approved'
```

### Thêm Analytics Tracking
Track engagement sau khi post:
```
Schedule (daily) → Fetch Twitter Analytics
                        → Fetch LinkedIn Analytics
                        → Update Sheet với metrics
```

### Thêm AI Content Generation
Dùng AI để tạo content tự động:
```
Schedule (weekly) → AI Generate Content Ideas
                          │
                          ▼
                     Add to Sheet as 'draft'
```
