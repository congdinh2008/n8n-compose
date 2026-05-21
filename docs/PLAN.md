# 📋 Kế hoạch triển khai N8N Workflows cho User Việt Nam

> **Đối tượng:** Cá nhân và Doanh nghiệp Việt Nam
> **Phiên bản:** N8N Community (self-hosted, free tier)
> **Ngày tạo:** 2026-05-05

---

## 🎯 Mục tiêu

Xây dựng bộ sưu tập workflows hoàn chỉnh, sẵn sàng import vào n8n, bao gồm:
- **Workflow JSON files** — sẵn sàng import trực tiếp
- **Documentation** — hướng dẫn chi tiết từng workflow bằng tiếng Việt
- **Community notes** — cảnh báo các tính năng cần customize/test cho bản community

---

## 📁 Cấu trúc thư mục đề xuất

```
n8n-compose/
├── workflows/
│   ├── README.md                    # Master catalog
│   ├── personal/
│   │   ├── 01-email-inbox-zero/
│   │   │   ├── workflow.json
│   │   │   └── GUIDE.md
│   │   ├── 02-daily-task-digest/
│   │   ├── 03-expense-tracker/
│   │   ├── 04-subscription-tracker/
│   │   ├── 05-content-scheduler/
│   │   ├── 06-learning-digest/
│   │   ├── 07-habit-tracker/
│   │   └── 08-meeting-notes/
│   ├── enterprise/
│   │   ├── 01-lead-capture-crm/
│   │   ├── 02-email-campaign/
│   │   ├── 03-order-fulfillment/
│   │   ├── 04-customer-support/
│   │   ├── 05-social-media-posting/
│   │   ├── 06-analytics-reporting/
│   │   ├── 07-employee-onboarding/
│   │   ├── 08-leave-approval/
│   │   ├── 09-invoice-generation/
│   │   └── 10-re-engagement-campaign/
│   ├── education/
│   │   ├── 01-quiz-generator-v3/    # Đã có
│   │   ├── 02-google-form-email/    # Đã có
│   │   ├── 03-auto-grading/
│   │   ├── 04-student-progress/
│   │   └── 05-parent-notification/
│   └── common/
│       ├── error-handler.json        # Reusable error handling sub-workflow
│       ├── rate-limiter.json         # Rate limiting pattern
│       └── data-validator.json       # Input validation pattern
├── docs/
│   └── workflows/                   # Mirror structure with detailed guides
└── templates/                       # Pre-configured credential templates
```

---

## 🗂️ Danh sách Workflows cần triển khai

### 👤 Personal Workflows (8 workflows)

| # | Workflow | Độ khó | Triggers | Actions | Community Notes |
|---|----------|--------|----------|---------|-----------------|
| 01 | **Email Inbox Zero** | ⭐⭐ | Gmail Trigger | Label, Archive, Delete | Gmail OAuth cần reconnect định kỳ |
| 02 | **Daily Task Digest** | ⭐⭐ | Schedule | Todoist, Google Calendar, Telegram | Todoist node có sẵn, Telegram cần bot token |
| 03 | **Expense Tracker** | ⭐⭐⭐ | Email/IMAP Trigger | Google Sheets, Telegram Alert | IMAP polling mỗi 5 phút, parse email body bằng regex |
| 04 | **Subscription Tracker** | ⭐⭐ | Schedule | Google Sheets, Notify | Cần Google Sheets OAuth |
| 05 | **Content Scheduler** | ⭐⭐⭐ | Schedule | Twitter, LinkedIn, Facebook nodes | Twitter API v2 cần bearer token, LinkedIn node có sẵn |
| 06 | **Learning Digest** | ⭐⭐⭐ | Schedule | RSS, HTTP Request, AI Summary | RSS node có sẵn, AI cần OpenAI/Ollama credential |
| 07 | **Habit Tracker** | ⭐⭐ | Schedule + Webhook | Google Sheets, Telegram | Webhook cần ngrok/public URL cho testing |
| 08 | **Meeting Notes AI** | ⭐⭐⭐⭐ | Schedule + HTTP | Transcription, Notion, Email | AI transcription cần OpenAI/Claude API (có phí) |

### 🏢 Enterprise Workflows (10 workflows)

| # | Workflow | Độ khó | Triggers | Actions | Community Notes |
|---|----------|--------|----------|---------|-----------------|
| 01 | **Lead Capture & CRM** | ⭐⭐⭐ | Webhook/Google Sheets | Gmail, Slack, HubSpot/Airtable | HubSpot node có sẵn, Airtable node có sẵn |
| 02 | **Email Campaign** | ⭐⭐⭐ | Webhook/Schedule | SendGrid/Mailchimp, Wait nodes | SendGrid node có sẵn, Wait nodes hoạt động tốt |
| 03 | **Order Fulfillment** | ⭐⭐⭐⭐ | Shopify/Google Sheets | Gmail, Slack, Shipping API | Shopify node có sẵn, cần HTTP Request cho shipping VN |
| 04 | **Customer Support** | ⭐⭐⭐⭐ | Gmail Trigger | AI classification, Ticket system | AI cần external API, ticket system dùng Google Sheets |
| 05 | **Social Media Posting** | ⭐⭐⭐ | Schedule/Google Sheets | Twitter, LinkedIn, Facebook | Cần API tokens cho từng platform |
| 06 | **Analytics Reporting** | ⭐⭐⭐ | Schedule | HTTP Request, Google Sheets, Slack | Google Analytics node có sẵn |
| 07 | **Employee Onboarding** | ⭐⭐⭐ | Webhook/Manual | Google Workspace, Slack, Email | Google Workspace node cần domain admin |
| 08 | **Leave Approval** | ⭐⭐⭐ | Webhook/Google Sheets | Gmail, Google Calendar, Sheets | Logic validation bằng Code node |
| 09 | **Invoice Generation** | ⭐⭐⭐⭐ | Schedule | Google Sheets, Email, PDF | PDF generation cần external service hoặc Code node |
| 10 | **Re-engagement Campaign** | ⭐⭐⭐ | Schedule | Email, CRM update, Segmentation | Logic phân segment bằng Code node |

### 🎓 Education Workflows (5 workflows)

| # | Workflow | Độ khó | Triggers | Actions | Community Notes |
|---|----------|--------|----------|---------|-----------------|
| 01 | **Quiz Generator V3** | ⭐⭐⭐ | Webhook | Google Drive, OpenAI, Google Forms | ✅ Đã có — cần review và optimize |
| 02 | **Google Form → Email/Slack** | ⭐⭐ | Google Sheets Trigger | Gmail, Slack | ✅ Đã có — cần hoàn thiện docs |
| 03 | **Auto Grading** | ⭐⭐⭐ | Google Sheets Trigger | Calculate, Email, Sheets | Logic chấm điểm bằng Code node |
| 04 | **Student Progress** | ⭐⭐ | Schedule | Google Sheets, Email Report | Report generation bằng Code + Sheets |
| 05 | **Parent Notification** | ⭐⭐ | Google Sheets Trigger | Email, Telegram/SMS | SMS cần external API (Twilio không có free tier VN) |

### 🔧 Common/Reusable Patterns (3 workflows)

| # | Pattern | Mô tả | Sử dụng |
|---|---------|-------|---------|
| 01 | **Error Handler** | Sub-workflow xử lý lỗi chung | Import vào mọi workflow |
| 02 | **Rate Limiter** | Giới hạn API calls | Dùng trước HTTP Request nodes |
| 03 | **Data Validator** | Validate input data | Dùng sau Webhook/Trigger nodes |

---

## 🚀 Lộ trình triển khai

### Phase 1: Foundation (Week 1-2)
**Mục tiêu:** Xây dựng hạ tầng và workflows cơ bản nhất

- [ ] Tạo cấu trúc thư mục
- [ ] Tạo 3 common patterns (error handler, rate limiter, validator)
- [ ] Hoàn thiện 2 workflows đã có (quiz generator, google form)
- [ ] Tạo README master catalog
- [ ] Viết template GUIDE.md chuẩn

**Deliverables:**
```
workflows/common/           ✅ 3 patterns
workflows/education/        ✅ 2 existing workflows (reviewed)
workflows/README.md         ✅ Master catalog
docs/workflows/TEMPLATE.md  ✅ Guide template
```

### Phase 2: Personal Workflows (Week 3-5)
**Mục tiêu:** 8 personal productivity workflows

**Priority order:**
1. Daily Task Digest (⭐⭐) — dễ, high value
2. Expense Tracker (⭐⭐⭐) — popular use case
3. Subscription Tracker (⭐⭐) — simple
4. Email Inbox Zero (⭐⭐) — foundational
5. Content Scheduler (⭐⭐⭐) — social media
6. Habit Tracker (⭐⭐) — simple
7. Learning Digest (⭐⭐⭐) — AI integration
8. Meeting Notes AI (⭐⭐⭐⭐) — complex, last

**Deliverables per workflow:**
```
workflows/personal/XX-name/
├── workflow.json            # Ready to import
└── GUIDE.md                 # Detailed instructions
    ├── Mục tiêu
    ├── Sơ đồ luồng
    ├── Cấu hình Credentials
    ├── Test guide
    ├── Troubleshooting
    └── Community version notes
```

### Phase 3: Enterprise Workflows (Week 6-10)
**Mục tiêu:** 10 enterprise workflows

**Priority order:**
1. Lead Capture & CRM (⭐⭐⭐) — highest demand
2. Order Fulfillment (⭐⭐⭐⭐) — e-commerce core
3. Customer Support (⭐⭐⭐⭐) — support automation
4. Email Campaign (⭐⭐⭐) — marketing
5. Social Media Posting (⭐⭐⭐) — marketing
6. Analytics Reporting (⭐⭐⭐) — reporting
7. Re-engagement Campaign (⭐⭐⭐) — retention
8. Leave Approval (⭐⭐⭐) — HR
9. Employee Onboarding (⭐⭐⭐) — HR
10. Invoice Generation (⭐⭐⭐⭐) — finance, complex

**Deliverables per workflow:**
```
workflows/enterprise/XX-name/
├── workflow.json
├── GUIDE.md
└── credentials-template.json   # Sample credential structure
```

### Phase 4: Education Workflows (Week 11-12)
**Mục tiêu:** 5 education workflows

**Priority order:**
1. Auto Grading (⭐⭐⭐) — high value for teachers
2. Student Progress (⭐⭐) — reporting
3. Parent Notification (⭐⭐) — communication
4. Quiz Generator V3 (review) (⭐⭐⭐) — already exists
5. Google Form → Email/Slack (review) (⭐⭐) — already exists

### Phase 5: Polish & Documentation (Week 13-14)
**Mục tiêu:** Hoàn thiện documentation và testing

- [ ] Review tất cả workflows
- [ ] Test trên n8n community version
- [ ] Update community notes
- [ ] Viết quick reference card
- [ ] Tạo video screenshots (optional)
- [ ] Export final workflow bundle

---

## ⚠️ Lưu ý cho N8N Community Version

### Tính năng có sẵn ✅
- Tất cả core nodes (Code, HTTP Request, IF, Switch, Merge, etc.)
- 300+ app integrations (Gmail, Slack, Google Sheets, etc.)
- Webhook triggers
- Schedule triggers
- Wait nodes
- Error handling nodes
- Expressions & JavaScript
- Self-hosted (no execution limit)

### Tính năng cần lưu ý ⚠️
- **AI/LangChain nodes:** Có sẵn nhưng cần external API key (OpenAI, Anthropic)
- **OAuth2 credentials:** Cần reconnect định kỳ khi token expire
- **Execution data storage:** Dùng SQLite (default), nên switch sang PostgreSQL cho production
- **Queue mode:** Không available trong community — xử lý concurrent executions hạn chế
- **Advanced permissions:** Không có role-based access (chỉ có 1 admin user)
- **n8n-deploy:** Không có — cần tự setup Docker/infrastructure

### Customization cần thiết 🔧
- **Vietnamese services:** Shipping API (Giao Hàng Nhanh, Viettel Post), SMS (Vietguys, Esms.vn) — dùng HTTP Request node
- **Payment gateways:** MoMo, VNPay, ZaloPay — dùng HTTP Request node (không có native nodes)
- **Date/time format:** Set `GENERIC_TIMEZONE=Asia/Ho_Chi_Minh` trong docker-compose
- **Email templates:** Viết bằng tiếng Việt, encoding UTF-8

### Testing recommendations 🧪
1. Test mỗi workflow với **data mẫu** trước khi dùng production
2. Kiểm tra **rate limits** của external APIs
3. Setup **error handling** cho mọi workflow quan trọng
4. Backup **workflows exports** định dạng JSON
5. Kiểm tra **credentials expiration** hàng tháng

---

## 📐 Template cấu trúc GUIDE.md

Mỗi workflow sẽ có file `GUIDE.md` theo template sau:

```markdown
# [Tên Workflow]

## Mục tiêu
[Mô tả ngắn gọn workflow làm gì]

## Đối tượng sử dụng
[Cá nhân/Doanh nghiệp/Giáo viên — ai dùng workflow này]

## Sơ đồ luồng
[ASCII diagram hoặc mô tả flow]

## Nodes chi tiết
| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| ...  | ...  | ...           | ...         |

## Cài đặt

### Bước 1: Chuẩn bị Credentials
[List tất cả credentials cần thiết và hướng dẫn tạo]

### Bước 2: Import Workflow
[Instructions to import JSON vào n8n]

### Bước 3: Cấu hình
[Step-by-step configuration]

### Bước 4: Test
[How to test workflow với data mẫu]

## Troubleshooting
| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|

## ⚠️ Lưu ý Community Version
[Specific notes cho n8n community users]

## Mở rộng
[Suggestions for extending this workflow]
```

---

## 📊 Metrics & Success Criteria

### Workflow Quality
- [ ] Mỗi workflow import thành công không lỗi
- [ ] Chạy đúng với data mẫu
- [ ] Error handling được implement
- [ ] Documentation đầy đủ tiếng Việt

### Coverage
- [ ] 8 Personal workflows ✅
- [ ] 10 Enterprise workflows ✅
- [ ] 5 Education workflows ✅
- [ ] 3 Common patterns ✅
- **Total: 26 workflows + patterns**

### Documentation
- [ ] 26 GUIDE.md files
- [ ] 1 Master README.md
- [ ] 1 Quick Reference Card
- [ ] 1 Credentials setup guide

---

## 🔗 Dependencies & Resources

### External APIs cần thiết
| Service | Purpose | Free tier | Cost if over limit |
|---------|---------|-----------|-------------------|
| OpenAI | AI summaries, transcription | $5 credit new account | Pay per use |
| SendGrid | Email sending | 100 emails/day free | Paid plans |
| Telegram Bot | Notifications | Free | Free |
| Google APIs | Sheets, Gmail, Calendar | Free (quota) | Paid if over |
| Twilio | SMS (optional) | Trial credit | Pay per SMS |

### Vietnamese services (HTTP Request)
| Service | Purpose | API docs |
|---------|---------|----------|
| Giao Hàng Nhanh | Shipping | https://docs.giaohangnhanh.vn |
| MoMo | Payment | https://developers.momo.vn |
| VNPay | Payment | https://sandbox.vnpayment.vn |
| Esms.vn | SMS | https://www.esms.vn |

---

## 📝 Notes

- Tất cả workflows được viết bằng **tiếng Việt** với thuật ngữ kỹ thuật **tiếng Anh**
- JSON workflows có thể **import trực tiếp** vào n8n
- Community notes được đánh dấu ⚠️ để user biết cần test kỹ
- Mọi workflows đều có **error handling** cơ bản
- Credentials được **không hardcoded** — dùng credential manager của n8n

---

**Created:** 2026-05-05
**Status:** Plan — awaiting approval
**Next Step:** Phase 1 — Foundation
