# 🏢 Enterprise: Customer Support Automation

## Mục tiêu
Tự động hóa quy trình **hỗ trợ khách hàng** qua email:
- Phân loại yêu cầu hỗ trợ tự động
- Tạo ticket và assign đúng team
- Xử lý refund tự động (nếu < threshold)
- Gửi phản hồi nhanh chóng
- SLA monitoring

## Đối tượng sử dụng
**Doanh nghiệp** - Customer support teams, helpdesk, bất kỳ ai xử lý email hỗ trợ từ khách hàng.

## Sơ đồ luồng
```
[Gmail Trigger (Support Email)]
         │
         ▼
[Parse & Classify Email]
  (Keyword matching)
         │
    ┌────┼────┐
    ▼    ▼    ▼
[Refund] [Question] [Tech Issue] [Complaint] [General]
    │       │         │            │          │
    ▼       ▼         ▼            ▼          ▼
[IF:     [Send     [Create      [Notify     [Send
 amount   FAQ]      High-Prio     Manager     Auto-
 < 500K?]            Ticket]      + Ticket    Reply]
    │
    ├─[Yes]→ Auto-approve
    │
    └─[No] → Manager Approval
         │
         ▼
   [Log to Google Sheets]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Gmail Trigger | Gmail | Poll new emails from support@ | Gmail OAuth2 |
| Parse & Classify | Code | Keyword matching VN/EN | None |
| Create Ticket | Google Sheets | Append row | Google Sheets OAuth2 |
| IF: Refund Amount | IF | Check < 500,000 VND | None |
| Send FAQ Response | Gmail | Template tiếng Việt | Gmail OAuth2 |
| Notify Tech Team | Slack | Message to #tech-support | Slack OAuth2 |
| Notify Manager | Slack/Email | Urgent alert | Slack/Gmail OAuth2 |
| Send Auto-Reply | Gmail | Ticket number + ETA | Gmail OAuth2 |

## Cài đặt

### Bước 1: Chuẩn bị Google Sheets Ticket System

Tạo Google Sheet với các columns:

| ticket_id | customer_email | subject | category | priority | status | created_at | assigned_to | resolved_at | sla_deadline |
|-----------|---------------|---------|----------|----------|--------|------------|-------------|-------------|--------------|
| TKT-123 | a@email.com | Lỗi đăng nhập | Technical | High | Open | 2026-05-05 | tech-team | | 2026-05-06 |

**SLA Deadlines:**
- Technical Issue: 4 hours
- Refund: 24 hours
- General: 48 hours
- Complaint: 2 hours

### Bước 2: Cấu hình Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail → Connect với support email |
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |
| **Slack OAuth2** | Settings → Credentials → Add → Slack → Connect với workspace |

### Bước 3: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/enterprise/04-customer-support/workflow.json`
4. Click **Import**

### Bước 4: Cấu hình Nodes

**1. Gmail Trigger:**
- Set **Email** = support@yourdomain.com
- Poll interval: Mỗi 5 phút

**2. Parse & Classify Email:**
- Review keywords trong Code node
- Thêm/bớt keywords theo nhu cầu

**3. Create Ticket:**
- Set **Document ID** = Sheet ID
- Set **Sheet Name** = tên sheet tickets

**4. Send FAQ Response:**
- Customize FAQ template theo sản phẩm/dịch vụ của bạn

**5. Notify Tech Team/Manager:**
- Set **Channel** = `#tech-support` hoặc `#urgent-tickets`
- Customize message format

### Bước 5: Test

**Gửi test email đến support@ với các scenarios:**

1. **Refund Request:**
   ```
   Subject: Yêu cầu hoàn tiền đơn hàng #12345
   Body: Tôi muốn hoàn tiền cho đơn hàng #12345, số tiền 300,000đ
   ```

2. **Technical Issue:**
   ```
   Subject: Không đăng nhập được
   Body: Tôi bị lỗi không đăng nhập vào tài khoản được
   ```

3. **Product Question:**
   ```
   Subject: Hỏi về tính năng
   Body: Cho tôi hỏi sản phẩm X có tính năng Y không?
   ```

**Kiểm tra:**
1. ✅ Ticket được tạo trong Google Sheets?
2. ✅ Email phản hồi đúng category?
3. ✅ Slack notifications đến đúng channel?
4. ✅ Refund < 500K được auto-approve?

## Cấu trúc dữ liệu

### Email Classification Keywords

| Category | Vietnamese Keywords | English Keywords |
|----------|-------------------|------------------|
| Refund | hoàn tiền, trả lại, refund, hủy đơn | refund, return, cancel order |
| Technical | lỗi, error, bug, không hoạt động, bị hỏng | error, bug, not working, broken |
| Question | hỏi, tư vấn, thông tin, giá, mua | question, info, price, buy, how to |
| Complaint | khiếu nại, phàn nàn, tệ, bực mình | complaint, terrible, frustrated |
| General | *(everything else)* | *(everything else)* |

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Trigger không hoạt động | Gmail credential sai | Reconnect Gmail OAuth2 |
| Classification sai | Keywords không đủ | Thêm keywords vào Code node |
| Ticket không tạo | Sheet ID sai | Kiểm tra Sheet ID và permissions |
| Slack không gửi | Channel không tồn tại | Tạo channel hoặc đổi tên |
| SLA bị vượt | Workflow chạy chậm | Tăng poll frequency |

## ⚠️ Lưu ý Community Version

- ✅ **Gmail node** có sẵn, hoạt động tốt
- ✅ **Google Sheets node** có sẵn
- ✅ **Slack node** có sẵn
- ⚠️ **OAuth2 credentials** cần reconnect định kỳ
- ⚠️ **Polling interval** tối thiểu 1 phút (có thể delay)
- 💡 **Tip**: Dùng Google Sheets làm ticket system đơn giản. Scale lên thì dùng Zendesk/Freshdesk nodes

## Mở rộng

### Thêm AI Classification
Dùng OpenAI/AI node để phân loại thông minh hơn:
```
Gmail Trigger → AI Classification ( thay vì keyword matching)
```

### Thêm Zendesk/Freshdesk Integration
Thay thế Google Sheets bằng ticket system chuyên nghiệp:
```
Classify → Create Zendesk Ticket → Assign Group
```

### Thêm Customer Satisfaction Survey
Sau khi resolve ticket, gửi survey:
```
Ticket Resolved → Wait 24h → Send CSAT Survey
                                      │
                                      ▼
                               Log Score to Sheets
```

### Thêm SLA Monitoring Workflow
Tạo workflow riêng để monitor SLA:
```
Schedule (every hour) → Check Open Tickets
                              │
                              ▼
                    IF past deadline → Alert Manager
```

### Thêm Knowledge Base Auto-Reply
Dùng AI search knowledge base và generate response:
```
Classify as Question → Search KB → Generate AI Response
                                          │
                                          ▼
                                     Send to Customer
```
