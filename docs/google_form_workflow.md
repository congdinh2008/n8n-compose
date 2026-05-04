# 📋 Hướng dẫn: Google Form to Email & Slack

> **File workflow:** `workflows/google_form_workflow.json`

## Mục tiêu

Tự động hóa quy trình xử lý đăng ký từ Google Form:
- Gửi email chào mừng đến khách hàng vừa đăng ký
- Thông báo lên kênh Slack `#sales` để team theo dõi lead mới

---

## Sơ đồ luồng

```
[Google Sheets Trigger]
  (Polling mỗi phút khi có response mới)
          │
          ├─────────────────────────────┐
          ▼                             ▼
[Send Welcome Email]          [Notify Sales Team]
  (Gmail → khách hàng)          (Slack → #sales)
```

---

## Các Nodes

### 1. Google Sheets Trigger (Form Responses)
| Thuộc tính | Giá trị |
|------------|---------|
| **Type** | `n8n-nodes-base.googleSheetsTrigger` |
| **Poll interval** | Mỗi phút (`everyMinute`) |
| **Document ID** | *(cần cấu hình — ID của Google Sheet gắn với Form)* |
| **Sheet Name** | *(cần cấu hình — tên sheet chứa responses)* |

> 💡 Google Form tự động lưu responses vào Google Sheets. Trigger sẽ detect row mới và kích hoạt workflow.

### 2. Send Welcome Email
| Thuộc tính | Giá trị |
|------------|---------|
| **Type** | `n8n-nodes-base.gmail` |
| **To** | `={{ $json.Email }}` |
| **Subject** | `Chào mừng bạn đã đăng ký!` |
| **Credential** | Gmail OAuth2 |

**Nội dung email:**
```
Xin chào {{ $json['Họ và tên'] }},

Cảm ơn bạn đã để lại thông tin. Đội ngũ tư vấn của chúng tôi
sẽ liên hệ với bạn trong thời gian sớm nhất.

Trân trọng,
Đội ngũ CSKH
```

### 3. Notify Sales Team
| Thuộc tính | Giá trị |
|------------|---------|
| **Type** | `n8n-nodes-base.slack` |
| **Channel** | `#sales` |
| **Credential** | Slack OAuth2 |

**Nội dung message Slack:**
```
🎉 *Khách hàng mới từ Google Form!*

*Họ và tên:* {{ $json['Họ và tên'] }}
*Email:* {{ $json.Email }}
*Số điện thoại:* {{ $json['Số điện thoại'] }}
```

---

## Cài đặt

### Bước 1: Tạo Google Form

1. Truy cập [Google Forms](https://forms.google.com)
2. Tạo form với các fields:
   - `Họ và tên` *(Text)*
   - `Email` *(Email)*
   - `Số điện thoại` *(Text)*
3. Vào **Responses** → Click biểu tượng Google Sheets để liên kết

### Bước 2: Lấy thông tin Google Sheets

```
URL: https://docs.google.com/spreadsheets/d/SHEET_ID/edit
                                                   ↑
                                         Copy phần này
```

Tên sheet mặc định: `Form Responses 1`

### Bước 3: Cấu hình Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets OAuth2 → Connect |
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail OAuth2 → Connect |
| **Slack OAuth2** | Settings → Credentials → Add → Slack OAuth2 → Connect với workspace |

### Bước 4: Import và cấu hình workflow

```
1. n8n Dashboard → Add workflow → Import from File
2. Chọn: workflows/google_form_workflow.json
3. Mở node "Google Sheets Trigger":
   - Document ID: [paste SHEET_ID]
   - Sheet Name: Form Responses 1
4. Gán credentials cho tất cả nodes
5. Save → Activate
```

---

## Cấu trúc dữ liệu

Khi Google Sheets Trigger kích hoạt, data truyền xuống có dạng:

```json
{
  "Họ và tên": "Nguyễn Văn A",
  "Email": "nguyenvana@email.com",
  "Số điện thoại": "0901234567",
  "Timestamp": "5/4/2026 13:00:00"
}
```

> ⚠️ Tên fields trong expressions (`$json['Họ và tên']`) phải **khớp chính xác** với tên cột trong Google Sheets (tức là tên câu hỏi trong Form).

---

## Test thủ công

1. Điền form thật → Google Sheets sẽ có 1 row mới
2. Vào n8n → Mở workflow → Click **"Test workflow"**
3. Kiểm tra:
   - Email đã đến hòm thư chưa?
   - Slack `#sales` có message không?

---

## Mở rộng

### Thêm điều kiện lọc (IF Node)

```
Trigger → IF (Email không rỗng)
               │ true
               ├─── Send Email
               └─── Notify Slack
               │ false
               └─── Stop (bỏ qua)
```

### Lưu vào Database

Thêm node **PostgreSQL** hoặc **Airtable** để lưu lead:
```
Trigger → [Save to DB] → Send Email
                       → Notify Slack
```

### Thêm CRM

Thêm node **HubSpot** hoặc **Salesforce** để tạo contact tự động:
```
Trigger → Create HubSpot Contact → Send Email → Notify Slack
```

---

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Trigger không kích hoạt | Sheet ID sai | Kiểm tra lại URL Google Sheets |
| `$json.Email` undefined | Tên cột không khớp | Mở Sheet, kiểm tra header row |
| Gmail không gửi được | Credential hết hạn | Reconnect Gmail OAuth2 |
| Slack không nhận | Channel không tồn tại | Tạo channel `#sales` hoặc đổi tên |
| Workflow không active | Chưa bật | Toggle Active ở góc phải trên |
