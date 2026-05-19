# 📊 Enterprise: Analytics Reporting

## Mục tiêu
Tự động **tổng hợp báo cáo analytics hàng ngày** từ nhiều nguồn:
- Google Analytics (website traffic)
- Social Media (Facebook, LinkedIn, Twitter)
- Email Campaign (SendGrid/Mailchimp)
- Tự động generate insights và gửi báo cáo

## Đối tượng sử dụng
**Doanh nghiệp** - Marketing teams, management, bất kỳ ai cần theo dõi performance hàng ngày.

## Sơ đồ luồng
```
[Schedule Trigger - 9 AM Daily]
         │
    ┌────┼────┐
    ▼    ▼    ▼
[GA4] [Social] [Email]
    │    │    │
    └────┼────┘
         ▼
[Aggregate & Generate Report]
  (Auto insights)
         │
    ┌────┼────┐
    ▼    ▼    ▼
[Sheets] [Email] [Slack]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Schedule Trigger | Schedule | Daily 9 AM | None |
| Fetch GA Data | Code/HTTP | GA4 API | Google OAuth2 |
| Fetch Social Data | Code/HTTP | FB/LinkedIn/Twitter APIs | API tokens |
| Fetch Email Stats | Code/HTTP | SendGrid/Mailchimp API | API key |
| Aggregate Report | Code | Insights generation | None |
| Save to Sheets | Google Sheets | Append row | Google Sheets OAuth2 |
| Send Email Report | Gmail | Vietnamese template | Gmail OAuth2 |
| Send Slack Report | Slack | Message to #analytics | Slack OAuth2 |

## Cài đặt

### Bước 1: Tạo Google Sheets Report Log

Tạo Google Sheet để lưu lịch sử báo cáo:

| date | visitors | page_views | bounce_rate | social_followers | social_engagement | email_sends | email_open_rate | insights |
|------|----------|------------|-------------|-----------------|-------------------|-------------|-----------------|----------|
| 2026-05-05 | 1250 | 3420 | 42.5% | 9220 | 1083 | 2450 | 50.2% | Tất cả tốt |

### Bước 2: Cấu hình API Credentials

| Service | Hướng dẫn |
|---------|-----------|
| **Google Analytics 4** | GA4 Console → Create Property → Enable Data API → OAuth2/Service Account |
| **Facebook Graph API** | Facebook Developers → Create App → Get Page Token |
| **LinkedIn API** | LinkedIn Developers → Create App → Get Access Token |
| **Twitter API** | Twitter Developer Portal → Get Bearer Token |
| **SendGrid** | SendGrid Dashboard → API Keys → Create API Key |

### Bước 3: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/enterprise/06-analytics-reporting/workflow.json`
4. Click **Import**

### Bước 4: Thay thế Mock Data bằng API Calls

**Hiện tại workflow dùng mock data.** Để dùng data thật:

**Google Analytics 4:**
```javascript
// Thay thế Code node bằng HTTP Request node:
// Method: POST
// URL: https://analyticsdata.googleapis.com/v1beta/properties/PROPERTY_ID:runReport
// Auth: OAuth2
// Body: {
//   "dateRanges": [{"startDate": "yesterday", "endDate": "yesterday"}],
//   "metrics": [{"name": "activeUsers"}, {"name": "screenPageViews"}, {"name": "bounceRate"}]
// }
```

**Facebook:**
```javascript
// HTTP Request:
// URL: https://graph.facebook.com/v18.0/PAGE_ID?fields=fan_count,engagement
// Headers: Authorization: Bearer ACCESS_TOKEN
```

**SendGrid:**
```javascript
// HTTP Request:
// URL: https://api.sendgrid.com/v3/stats?start_date=YESTERDAY&end_date=YESTERDAY
// Headers: Authorization: Bearer API_KEY
```

### Bước 5: Cấu hình Output Nodes

**1. Save to Google Sheets:**
- Set **Document ID** = Sheet ID của report log
- Set **Sheet Name** = tên sheet

**2. Send Email Report:**
- Set **To** = email management team (có thể nhiều email cách nhau bởi dấu phẩy)
- Gmail credential đã được gán

**3. Send Slack Report:**
- Set **Channel** = `#analytics` (hoặc channel của bạn)
- Slack credential đã được gán

### Bước 6: Test

1. Click **Test Workflow**
2. Kiểm tra:
   - ✅ Report được tạo đúng không?
   - ✅ Google Sheets có row mới?
   - ✅ Email đã gửi?
   - ✅ Slack có message?
3. Nếu OK → **Activate** workflow

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| API 401 | Token expire | Refresh/reconnect credentials |
| Google Sheets error | Sheet ID sai | Kiểm tra lại URL |
| Không nhận email | Gmail credential invalid | Reconnect Gmail OAuth2 |
| Slack không gửi | Channel không tồn tại | Tạo channel `#analytics` |

## ⚠️ Lưu ý Community Version

- ✅ **Schedule trigger** hoạt động tốt
- ✅ **HTTP Request node** có sẵn cho mọi API
- ✅ **Gmail/Slack/Google Sheets nodes** có sẵn
- ⚠️ **API rate limits** - kiểm tra giới hạn của từng service
- ⚠️ **OAuth2 credentials** cần reconnect định kỳ
- 💡 **Tip**: Bắt đầu với mock data, sau đó gradually kết nối APIs thật
