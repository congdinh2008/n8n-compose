# 👥 Enterprise: Employee Onboarding

## Mục tiêu
Tự động hóa quy trình **onboarding nhân viên mới**:
- Gửi welcome email với first-day agenda
- Thông báo IT team chuẩn bị equipment
- Thông báo manager về nhân viên mới
- Log toàn bộ vào Google Sheets

## Đối tượng sử dụng
**Doanh nghiệp** - HR teams, IT departments, managers.

## Sơ đồ luồng
```
[Webhook: New Employee]
         │
         ▼
[Validate Employee Data]
         │
    ┌────┴────┐
    ▼         ▼
[Prepare     [Assign Equipment
 Welcome]     by Role]
    │         │
    ▼         ▼
[Send      [Notify IT Team
 Welcome]   (Slack)]
    │
    ▼
[Notify Manager]
    │
    └────┬────┘
         ▼
[Log to Google Sheets]
         │
         ▼
[Return Response]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Webhook | Webhook | POST /webhook/new-employee | None |
| Validate | Code | Required fields, email | None |
| Prepare Welcome | Code | Email template VN | None |
| Assign Equipment | Code | Role-based mapping | None |
| Send Welcome Email | Gmail | Welcome template | Gmail OAuth2 |
| Notify IT Team | Slack | Equipment details | Slack OAuth2 |
| Notify Manager | Gmail | Manager notification | Gmail OAuth2 |
| Log to Sheets | Google Sheets | Append employee | Google Sheets OAuth2 |

## Cài đặt

### Bước 1: Tạo Google Sheets Employee Tracker

| employee_id | name | email | department | role | manager | start_date | status | equipment | created_at |
|-------------|------|-------|------------|------|---------|------------|--------|-----------|------------|

### Bước 2: Customize Equipment Mapping

Mở node "Assign Equipment by Role" và chỉnh sửa:
```javascript
const EQUIPMENT = {
  standard: ['Laptop', 'Monitor', 'Keyboard', 'Mouse', 'Headset'],
  developer: ['Laptop', 'Monitor', 'Keyboard', 'Mouse', 'Headset', 'Docking Station'],
  designer: ['Laptop', 'Monitor', 'Keyboard', 'Mouse', 'Headset', 'Drawing Tablet'],
  sales: ['Laptop', 'Headset', 'Mobile Phone'],
  manager: ['Laptop', 'Monitor', 'Keyboard', 'Mouse', 'Headset']
};
```

### Bước 3: Test

```bash
curl -X POST https://your-n8n.com/webhook/new-employee \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nguyễn Văn A",
    "email": "nguyenvana@company.com",
    "personal_email": "nguyenvana@gmail.com",
    "department": "Engineering",
    "role": "developer",
    "start_date": "2026-05-15",
    "manager": "Trần Quản Lý",
    "manager_email": "tranquanly@company.com",
    "address": "123 Đường ABC, Quận 1, TP.HCM"
  }'
```

## ⚠️ Lưu ý Community Version

- ⚠️ **Google Workspace/Slack account creation** không có native nodes - cần dùng HTTP Request
- 💡 **Tip**: Bắt đầu với email notifications và equipment assignment, sau đó thêm account creation

## Mở rộng

### Thêm Google Workspace Account Creation
Dùng Google Admin API qua HTTP Request node.

### Thêm Slack Invite
Dùng Slack API hoặc admin invite links.

### Thêm Payroll Setup
Gửi thông tin ngân hàng cho payroll team.
