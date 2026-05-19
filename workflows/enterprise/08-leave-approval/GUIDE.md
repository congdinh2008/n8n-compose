# 🏖️ Enterprise: Leave Approval

## Mục tiêu
Tự động hóa **quy trình xin nghỉ phép**:
- Nhân viên gửi đơn qua webhook
- Validate và tính số ngày phép
- Kiểm tra số dư phép
- Gửi manager duyệt
- Cập nhật balance và thông báo

## Đối tượng sử dụng
**Doanh nghiệp** - HR departments, managers, employees.

## Sơ đồ luồng
```
[Webhook: Employee submits leave]
         │
         ▼
[Validate Leave Request]
  (Fields, dates, leave type)
         │
         ▼
[Get Leave Balance]
  (Google Sheets)
         │
         ▼
[Check Balance & Overlaps]
         │
    ┌────┴────┐
    ▼         ▼
[IF: Valid Request?]
    │ yes           │ no
    ▼               ▼
[Send to        [Reject &
 Manager]         Notify]
    │
    ▼
[Wait for Manager Response]
  (Email reply or webhook)
    │
    ├─ APPROVE → Update sheets, notify employee & HR
    └─ REJECT → Notify employee with reason
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Webhook (Leave Request) | Webhook | POST /webhook/leave-request | None |
| Validate Leave Request | Code | Field & date validation | None |
| Get Leave Balance | Google Sheets | Search by employee_id | Google Sheets OAuth2 |
| Check Balance & Overlaps | Code | Balance & date check | None |
| IF: Valid Request? | IF | validation_passed | None |
| Send to Manager | Gmail | Approval request template | Gmail OAuth2 |
| Notify Employee (Rejected) | Gmail | Rejection template | Gmail OAuth2 |
| Log to Sheets | Google Sheets | Append row | Google Sheets OAuth2 |

## Cài đặt

### Bước 1: Tạo Google Sheets Leave Management

**Sheet 1 - Leave Balances:**

| employee_id | employee_name | annual_leave | unpaid_leave | sick_leave | maternity_leave |
|-------------|--------------|--------------|--------------|------------|-----------------|
| EMP-001 | Nguyễn Văn A | 12 | 30 | 15 | 180 |
| EMP-002 | Trần Thị B | 10 | 30 | 15 | 180 |

**Sheet 2 - Leave Records:**

| request_id | employee_id | employee_name | leave_type | start_date | end_date | leave_days | reason | status | created_at |
|------------|-------------|--------------|------------|------------|----------|------------|--------|--------|------------|
| LEAVE-001 | EMP-001 | Nguyễn Văn A | Phép năm | 2026-05-20 | 2026-05-22 | 3 | Việc gia đình | approved | 2026-05-05 |

**Lấy Sheet ID:**
```
URL: https://docs.google.com/spreadsheets/d/SHEET_ID/edit
                                                   ↑
                                         Copy phần này
```

### Bước 2: Hiểu Vietnamese Leave Types

| Leave Type | Vietnamese | Default Days |
|------------|-----------|--------------|
| `annual_leave` | Phép năm | 12 days/year |
| `unpaid_leave` | Phép không lương | 30 days/year |
| `sick_leave` | Ốm | 15 days/year |
| `maternity_leave` | Thai sản | 180 days |
| `bereavement_leave` | Tang chế | 5 days |
| `personal_leave` | Việc riêng | 3 days |
| `training_leave` | Đào tạo | 30 days |

### Bước 3: Chuẩn bị Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail → Connect |

### Bước 4: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/enterprise/08-leave-approval/workflow.json`
4. Click **Import**

### Bước 5: Cấu hình

**1. Webhook:**
- Path đã set: `/webhook/leave-request`
- Full URL: `https://your-n8n.com/webhook/leave-request`

**2. Get Leave Balance:**
- Set **Document ID** = Sheet ID của Leave Balances
- Set **Sheet Name** = tên sheet balances

**3. Log to Sheets:**
- Set **Document ID** = Sheet ID của Leave Records
- Set **Sheet Name** = tên sheet records

**4. Email Templates:**
- Review và customize theo company policy
- Gán Gmail credential

### Bước 6: Test

**Test bằng curl:**
```bash
curl -X POST https://your-n8n.com/webhook/leave-request \
  -H "Content-Type: application/json" \
  -d '{
    "employee_id": "EMP-001",
    "employee_name": "Nguyễn Văn A",
    "employee_email": "nguyenvana@company.com",
    "manager_email": "manager@company.com",
    "start_date": "2026-05-20",
    "end_date": "2026-05-22",
    "leave_type": "annual_leave",
    "reason": "Việc gia đình"
  }'
```

**Kiểm tra:**
1. ✅ Leave request được validate đúng không?
2. ✅ Balance được check đúng không?
3. ✅ Manager đã nhận email chưa?
4. ✅ Sheets có update không?
5. ✅ Response trả về đúng không?

**Expected Response:**
```json
{
  "success": true,
  "message": "Leave request submitted for approval",
  "request_id": "LEAVE-1714924800000",
  "status": "pending_manager_approval"
}
```

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Validation fail | Missing fields | Kiểm tra request body |
| Balance không đúng | Sheet data sai | Update Leave Balances sheet |
| Manager không nhận email | Gmail credential sai | Reconnect OAuth2 |
| Date invalid | Format sai | Dùng YYYY-MM-DD format |

## ⚠️ Lưu ý Community Version

- ✅ **Webhook/Gmail/Sheets nodes** có sẵn
- ⚠️ **Manager approval** cần email reply parsing (chưa implement trong workflow này)
- 💡 **Tip**: Dùng Google Forms cho employee submissions thay vì webhook

## Mở rộng

### Thêm Manager Approval Workflow
Tạo webhook riêng cho manager approval:
```
Manager clicks approve link → Webhook → Update sheets → Notify employee
```

### Thêm Calendar Integration
Tự động add vào Google Calendar:
```
Leave Approved → Google Calendar (Create event) → Mark days as OOO
```

### Thêm HR Dashboard
Tổng hợp leave stats:
```
Schedule (weekly) → Query Leave Records → Generate report → Send to HR
```
