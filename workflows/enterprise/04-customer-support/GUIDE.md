# 🎧 Enterprise: Customer Support Automation

## Mục tiêu
Tự động hóa **hỗ trợ khách hàng**:
- Phân loại yêu cầu hỗ trợ từ email
- Routing đến đúng team/person
- Auto-respond với FAQs
- Tạo tickets trong Google Sheets
- SLA monitoring & escalation

## Đối tượng sử dụng
**Doanh nghiệp** - Support teams, customer service, help desks.

## Sơ đồ luồng
```
[Gmail Trigger - Support Email]
         │
         ▼
[Classify Request Type]
  (Code node - keywords)
         │
    ┌────┼────┬────┬────┐
    ▼    ▼    ▼    ▼    ▼
[Refund] [Q] [Tech] [Complaint] [General]
    │    │    │    │    │
    ▼    ▼    ▼    ▼    ▼
[IF:    [Send  [Create [Notify  [Send
Amount  FAQ]   High-  Manager] Auto-
< 500K?]        ticket]        reply]
 │ yes  │ no
 ▼      ▼
[Auto  [Manager
Approve] Approval]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Gmail Trigger | Gmail Trigger | Poll every 5 min | Gmail OAuth2 |
| Classify Request | Code | Vietnamese keywords | None |
| Create Ticket | Google Sheets | Append row | Google Sheets OAuth2 |
| Check Refund Amount | IF | < 500,000 VND | None |
| Auto-Approve Refund | Gmail/SendGrid | Approval email | Gmail OAuth2 |
| Send FAQ Response | Gmail/SendGrid | FAQ template | Gmail OAuth2 |
| Create Tech Ticket | Google Sheets + Slack | High priority | Slack OAuth2 |
| Notify Manager | Slack/Email | Urgent alert | Slack OAuth2 |
| Send Auto-Reply | Gmail/SendGrid | Ticket number | Gmail OAuth2 |

## Cài đặt

### Bước 1: Tạo Google Sheets Support Tracker

| ticket_id | customer_email | request_type | priority | status | created_at | assigned_to | resolved_at |
|-----------|---------------|--------------|----------|--------|------------|-------------|-------------|
| TKT-001 | customer@email.com | refund | low | resolved | 2026-05-05 | auto | 2026-05-06 |

### Bước 2: Cấu hình Keywords Classification

Mở node "Classify Request Type" và customize keywords:

```javascript
const classifications = {
  refund: ['hoàn tiền', 'refund', 'trả lại', 'return', 'hoàn lại'],
  question: ['hỏi', 'question', 'tư vấn', 'thông tin', 'how to'],
  technical: ['lỗi', 'error', 'bug', 'không hoạt động', 'bị hỏng'],
  complaint: ['khiếu nại', 'complaint', 'phàn nàn', 'tệ', 'dịch vụ kém'],
  general: [] // everything else
};
```

### Bước 3: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/enterprise/04-customer-support/workflow.json`
4. Click **Import**

### Bước 4: Cấu hình

**1. Gmail Trigger:**
- Set **Poll Interval** = Every 5 minutes
- Gán Gmail credential

**2. Create Ticket:**
- Set **Document ID** = Sheet ID của support tracker
- Set **Sheet Name** = tên sheet

**3. Send FAQ Response:**
- Customize FAQ template trong node
- Gán Gmail credential

**4. Notify Manager/Team:**
- Set **Channel** = `#support` hoặc `#tech-support`
- Gán Slack credential

### Bước 5: Test

**Gửi test email:**
- Subject: "Tôi muốn hoàn tiền" → Should classify as refund
- Subject: "Sản phẩm bị lỗi" → Should classify as technical
- Subject: "Cho tôi hỏi về giá" → Should classify as question

**Kiểm tra:**
1. ✅ Phân loại đúng không?
2. ✅ Ticket được tạo trong Sheets?
3. ✅ Response được gửi đúng?
4. ✅ Slack notifications có đến?

## Classification Logic

### Refund Request
**Keywords:** `hoàn tiền`, `refund`, `trả lại`, `return`, `hoàn lại`
**Action:** IF amount < 500,000 VND → Auto-approve, ELSE → Manager approval

### Product Question
**Keywords:** `hỏi`, `question`, `tư vấn`, `thông tin`, `how to`, `giá`, `price`
**Action:** Send FAQ response

### Technical Issue
**Keywords:** `lỗi`, `error`, `bug`, `không hoạt động`, `bị hỏng`, `không dùng được`
**Action:** Create high-priority ticket, notify tech team via Slack

### Complaint
**Keywords:** `khiếu nại`, `complaint`, `phàn nàn`, `tệ`, `dịch vụ kém`, `không hài lòng`
**Action:** Create urgent ticket, notify manager

### General
**Action:** Send auto-reply with ticket number

## ⚠️ Lưu ý Community Version

- ✅ **Gmail node** có sẵn
- ✅ **Google Sheets node** có sẵn
- ✅ **Code node** cho classification hoạt động tốt
- ⚠️ **OAuth2 credentials** cần reconnect định kỳ
- ⚠️ **Không có built-in ticket system** - dùng Google Sheets thay thế
- 💡 **Tip**: Với volume cao (>100 tickets/day), nên dùng dedicated helpdesk software

## SLA Guidelines

| Priority | Response Time | Resolution Time |
|----------|---------------|-----------------|
| Urgent (Complaint) | < 1 hour | < 4 hours |
| High (Technical) | < 2 hours | < 8 hours |
| Medium (Refund) | < 4 hours | < 24 hours |
| Low (Question/General) | < 8 hours | < 48 hours |

## Mở rộng

### Thêm AI Classification
Dùng OpenAI để phân loại thông minh hơn:
```
Email → OpenAI (Classify) → Route based on AI response
```

### Thêm Sentiment Analysis
Phát hiện customer anger level:
```javascript
const angryWords = ['tức giận', 'bực mình', 'không thể chấp nhận'];
const sentiment = angryWords.some(w => email.includes(w)) ? 'angry' : 'normal';
```

### Thêm CSAT Survey
Gửi survey sau khi resolve:
```
Ticket resolved → Wait 1 hour → Send CSAT survey email
```

### Integration với Live Chat
Kết nối website chat:
```
Website chat message → Same classification → Route to support
```
