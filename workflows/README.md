# 📦 N8N Workflow Collection

> **Bộ sưu tập workflows cho User Việt Nam** — Cá nhân & Doanh nghiệp
> **Phiên bản:** N8N Community (self-hosted)
> **Ngày cập nhật:** 2026-05-05

---

## 📊 Thống kê

| Category | Completed | Total | Status |
|----------|-----------|-------|--------|
| 👤 Personal | 4 | 8 | 🟡 50% |
| 🏢 Enterprise | 5 | 10 | 🟡 50% |
| 🎓 Education | 2 | 5 | 🟡 40% |
| 🔧 Common Patterns | 3 | 3 | ✅ 100% |
| **Total** | **14** | **26** | **🟡 54%** |

---

## 🗂️ Cấu trúc

```
workflows/
├── README.md                    # File này
├── personal/
│   ├── 01-email-inbox-zero/     ✅
│   ├── 02-daily-task-digest/    ✅
│   ├── 03-expense-tracker/      ✅
│   ├── 04-subscription-tracker/ ✅
│   ├── 05-content-scheduler/    🟡
│   ├── 06-learning-digest/      🟡
│   ├── 07-habit-tracker/        🟡
│   └── 08-meeting-notes/        🟡
├── enterprise/
│   ├── 01-lead-capture-crm/     ✅
│   ├── 02-email-campaign/       🟡
│   ├── 03-order-fulfillment/    🟡
│   ├── 04-customer-support/     🟡
│   ├── 05-social-media-posting/ 🟡
│   ├── 06-analytics-reporting/  🟡
│   ├── 07-employee-onboarding/  🟡
│   ├── 08-leave-approval/       🟡
│   ├── 09-invoice-generation/   🟡
│   └── 10-re-engagement-campaign/ 🟡
├── education/
│   ├── 01-quiz-generator-v3/    ✅ (existing)
│   ├── 02-google-form-email/    ✅ (existing)
│   ├── 03-auto-grading/         🟡
│   ├── 04-student-progress/     🟡
│   └── 05-parent-notification/  🟡
└── common/
    ├── error-handler.json       ✅
    ├── rate-limiter.json        ✅
    └── data-validator.json      ✅
```

---

## 🚀 Quick Start

### 1. Import Workflow

```
1. Mở n8n Dashboard → Workflows
2. Click "Add workflow" → Import from File
3. Chọn file JSON từ thư mục tương ứng
4. Cấu hình credentials
5. Activate workflow
```

### 2. Cấu hình Credentials

| Credential | Required For | Setup Guide |
|-----------|-------------|-------------|
| Gmail OAuth2 | Email workflows | Settings → Credentials → Gmail |
| Google Sheets OAuth2 | Sheet logging | Settings → Credentials → Google Sheets |
| Telegram Bot | Notifications | @BotFather → tạo bot → lấy token |
| Slack OAuth2 | Team notifications | Slack App → Install to workspace |
| OpenAI API | AI features | platform.openai.com → API Keys |

### 3. Environment Variables

Thêm vào `docker-compose.yml`:

```yaml
environment:
  - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
  - TZ=Asia/Ho_Chi_Minh
```

---

## 👤 Personal Workflows

### 01. Email Inbox Zero
**File:** `personal/01-email-inbox-zero/workflow.json`
**Độ khó:** ⭐⭐

Tự động phân loại email Gmail:
- VIP/Urgent → Star + Notify
- Newsletter → Label + Archive
- Promotion → Label + Mute
- Spam → Delete

**Credentials:** Gmail OAuth2, Telegram (optional)

---

### 02. Daily Task Digest
**File:** `personal/02-daily-task-digest/workflow.json`
**Độ khó:** ⭐⭐

Gửi morning briefing hàng ngày (8 AM):
- Tasks từ Todoist/Notion
- Calendar events
- Priority & focus items

**Credentials:** Gmail/Telegram, Todoist (optional), Notion (optional)

---

### 03. Expense Tracker
**File:** `personal/03-expense-tracker/workflow.json`
**Độ khó:** ⭐⭐⭐

Tự động theo dõi chi tiêu từ email ngân hàng:
- Parse giao dịch từ email (VCB, TPBank, MoMo, etc.)
- Categorize tự động (8 categories)
- Log vào Google Sheets
- Alert khi vượt budget

**Credentials:** Gmail, Google Sheets, Telegram

---

### 04. Subscription Tracker
**File:** `personal/04-subscription-tracker/workflow.json`
**Độ khó:** ⭐⭐

Theo dõi subscription hàng tháng:
- Netflix, Spotify, YouTube, etc.
- Phát hiện subscription mới/hủy
- Alert khi tăng giá >10%
- Monthly summary report

**Credentials:** Google Sheets, Telegram/Email

---

## 🏢 Enterprise Workflows

### 01. Lead Capture & CRM
**File:** `enterprise/01-lead-capture-crm/workflow.json`
**Độ khó:** ⭐⭐⭐

Tự động hóa quy trình tiếp nhận lead:
- Webhook từ website form
- Validate data + phone VN format
- Check duplicate
- Lead scoring theo source
- Welcome email + Notify team
- Route theo department

**Credentials:** Gmail, Google Sheets, Telegram/Slack

---

## 🎓 Education Workflows

### Quiz Generator V3
**File:** `../quiz_generator_workflow_v3.json` (root workflows/)
**Độ khó:** ⭐⭐⭐

Tạo quiz tự động từ tài liệu Markdown:
- Read từ Google Drive folder
- AI generates questions
- Output: Google Form hoặc JSON

**Credentials:** Google Drive, OpenAI

---

### Google Form → Email & Slack
**File:** `../google_form_workflow.json` (root workflows/)
**Độ khó:** ⭐⭐

Xử lý đăng ký từ Google Form:
- Google Sheets Trigger
- Send welcome email
- Notify sales team on Slack

**Credentials:** Google Sheets, Gmail, Slack

---

## 🔧 Common Patterns

### Error Handler
**File:** `common/error-handler.json`

Sub-workflow xử lý lỗi reusable:
- Format error message
- Severity classification
- Alert email/Slack
- Log to Google Sheets

**Usage:** Import và gọi qua webhook từ workflow chính.

---

### Rate Limiter
**File:** `common/rate-limiter.json`

Giới hạn API calls theo second:
- Batch processing
- Delay giữa batches
- Progress tracking

**Usage:** Wrap trước HTTP Request nodes để tránh 429 errors.

---

### Data Validator
**File:** `common/data-validator.json`

Validate input data:
- Required fields check
- Email format
- Vietnamese phone format
- Date validation
- XSS sanitization

**Usage:** Node đầu tiên sau Webhook trigger.

---

## ⚠️ Lưu ý Community Version

### Tính năng có sẵn ✅
- Tất cả core nodes
- 300+ app integrations
- Webhook & Schedule triggers
- Wait nodes
- Error handling
- JavaScript/Python code nodes
- Self-hosted (no execution limit)

### Cần lưu ý ⚠️
- **AI nodes:** Cần external API key (OpenAI, Anthropic)
- **OAuth2:** Reconnect định kỳ khi token expire
- **Database:** Dùng SQLite (default) → nên switch sang PostgreSQL
- **Queue mode:** Không available — hạn chế concurrent executions
- **Permissions:** Chỉ 1 admin user

### Customization cho Việt Nam 🔧
- **Shipping APIs:** GHN, Viettel Post — dùng HTTP Request node
- **Payment:** MoMo, VNPay, ZaloPay — dùng HTTP Request node
- **SMS:** Esms.vn, Vietguys — dùng HTTP Request node
- **Timezone:** `GENERIC_TIMEZONE=Asia/Ho_Chi_Minh`

---

## 📝 Workflow Template

Mỗi workflow folder có cấu trúc:

```
XX-workflow-name/
├── workflow.json           # n8n workflow (import được)
└── GUIDE.md                # Hướng dẫn chi tiết
```

---

## 📋 Checklist trước khi Production

- [ ] Test với data mẫu
- [ ] Cấu hình đầy đủ credentials
- [ ] Error handling hoạt động
- [ ] Rate limits được respect
- [ ] Google Sheets có đúng columns
- [ ] Email/Telegram notifications hoạt động
- [ ] Timezone đúng Asia/Ho_Chi_Minh
- [ ] Backup workflow exports
- [ ] Document customizations

---

## 🆘 Troubleshooting

| Vấn đề | Nguyên nhân | Giải pháp |
|--------|------------|-----------|
| Workflow không chạy | Chưa Activate | Toggle Active ON |
| Credential lỗi | Token expire | Reconnect credential |
| Webhook không nhận | URL sai hoặc chưa Activate | Kiểm tra webhook URL |
| Google Sheets lỗi | Sheet ID sai hoặc credential | Kiểm tra Sheet ID + OAuth |
| Telegram không gửi | Bot token hoặc chat_id sai | Kiểm tra @BotFather |

---

## 📚 Tham khảo

- [PLAN.md](../../PLAN.md) — Kế hoạch triển khai chi tiết
- [n8n Docs](https://docs.n8n.io)
- [n8n Templates](https://n8n.io/workflows)
- [Community Forum](https://community.n8n.io)

---

**Created:** 2026-05-05
**Status:** Work in Progress (4/26 workflows complete)
