# 👤 Enterprise: Employee Onboarding

## Mục tiêu
Tự động hóa **quy trình chào đón nhân viên mới**:
- Validate thông tin nhân viên
- Tạo danh sách thiết bị theo role
- Gửi email chào mừng
- Thông báo cho manager
- Announce trên Slack
- Log vào HR Google Sheets

## Đối tượng sử dụng
**Doanh nghiệp** - HR teams, managers, IT departments.

## Sơ đồ luồng
```
[Webhook: HR submits new employee]
         │
         ▼
[Validate Employee Data]
         │
         ▼
[Prepare Equipment List]
  (Based on role)
         │
         ▼
[Add to HR Google Sheets]
         │
    ┌────┴────┐
    ▼         ▼
[Welcome  [Notify
 Email]   Manager]
    │         │
    └────┬────┘
         ▼
   [Announce on Slack]
         │
         ▼
   [Return Success Response]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Webhook (New Employee) | Webhook | POST /webhook/new-employee | None |
| Validate Employee | Code | Required fields check | None |
| Prepare Equipment | Code | Role-based list | None |
| Add to HR Sheets | Google Sheets | Append row | Google Sheets OAuth2 |
| Welcome Email | Gmail | Vietnamese template | Gmail OAuth2 |
| Notify Manager | Gmail | Checklist template | Gmail OAuth2 |
| Announce on Slack | Slack | Welcome message | Slack OAuth2 |
| Return Response | Respond to Webhook | JSON response | None |

## Cài đặt

### Bước 1: Tạo Google Sheets HR Tracker

| employee_id | name | email | department | role | manager | start_date | status | created_at |
|-------------|------|-------|------------|------|---------|------------|--------|------------|
| EMP-123 | Nguyễn Văn A | a@company.com | Engineering | developer | Manager B | 2026-05-10 | onboarding | 2026-05-05 |

### Bước 2: Cấu hình Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail → Connect |
| **Slack OAuth2** | Settings → Credentials → Add → Slack → Connect |

### Bước 3: Customize Equipment List

Mở node "Prepare Equipment List" và cập nhật theo công ty:

```javascript
const equipmentByRole = {
  developer: ['Laptop', 'Màn hình phụ', 'Bàn phím', 'Chuột', 'Tai nghe', 'Dock'],
  designer: ['Laptop', 'Màn hình phụ', 'Bàn phím', 'Chuột', 'Tai nghe', 'Bảng vẽ'],
  manager: ['Laptop', 'Màn hình phụ', 'Bàn phím', 'Chuột'],
  general: ['Laptop', 'Bàn phím', 'Chuột']
};
```

### Bước 4: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/enterprise/07-employee-onboarding/workflow.json`
4. Click **Import**

### Bước 5: Test

**Test bằng curl:**
```bash
curl -X POST https://your-n8n.com/webhook/new-employee \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nguyễn Văn A",
    "email": "nguyenvana@company.com",
    "personal_email": "vana@email.com",
    "department": "Engineering",
    "role": "developer",
    "manager": "manager@company.com",
    "start_date": "2026-05-10",
    "address": "123 Đường ABC, Quận 1, TP.HCM"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Employee onboarding initiated",
  "employee_id": "EMP-1714924800000",
  "name": "Nguyễn Văn A",
  "start_date": "2026-05-10"
}
```

**Kiểm tra:**
1. ✅ Welcome email gửi cho nhân viên mới?
2. ✅ Manager nhận được notification?
3. ✅ Slack có announcement?
4. ✅ HR Sheets có row mới?

## ⚠️ Lưu ý Community Version

- ✅ **Webhook node** hoạt động tốt
- ✅ **Google Sheets node** có sẵn
- ✅ **Gmail/Slack nodes** có sẵn
- ⚠️ **OAuth2 credentials** cần reconnect định kỳ
- 💡 **Tip**: Có thể trigger từ Google Form thay vì webhook

## Mở rộng

### Thêm Account Creation
Tự động tạo accounts:
```
Validate → Create Google Workspace → Create Slack → Create GitHub
```

### Thêm Training Schedule
Tự động lên lịch training:
```
Add to HR Sheets → Create Calendar events for training sessions
```

### Thêm Document Signing
Gửi documents cần ký:
```
Welcome Email → Send employment contract (PDF) → Track signature
```

### Thêm IT Setup Workflow
Tự động notify IT team:
```
Equipment Prepared → Notify IT → Track setup completion
```
