# 👤 Personal: Expense Tracker

## Mục tiêu
Tự động **theo dõi chi tiêu** từ email sao kê ngân hàng:
- Parse thông tin giao dịch từ email (số tiền, merchant, ngày)
- Tự động phân loại chi tiêu (coffee, shopping, transport, v.v.)
- Log vào Google Sheets để theo dõi
- Alert nếu vượt ngân sách tháng

## Đối tượng sử dụng
**Cá nhân** - Bất kỳ ai muốn kiểm soát chi tiêu cá nhân tự động.

## Sơ đồ luồng
```
[Gmail Trigger - Bank Transaction Email]
         │
         ▼
[Parse Transaction Data]
  (Regex extract amount, merchant, date)
         │
         ▼
[Categorize Expense]
  (Based on merchant name)
         │
         ▼
[Log to Google Sheets]
         │
         ▼
[IF: Monthly Budget Exceeded?]
    │ yes          │ no
    ▼              ▼
[Telegram      [Silent Log]
 Alert]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Gmail Trigger | Gmail Trigger | Poll every 5 minutes | Gmail OAuth2 |
| Parse Transaction | Code | Regex extraction | None |
| Categorize Expense | Code | Merchant matching | None |
| Log to Google Sheets | Google Sheets | Append row | Google Sheets OAuth2 |
| IF: Budget Exceeded? | IF | Check monthly total | None |
| Telegram Alert | Telegram | Budget warning | Telegram Bot Token |

## Cài đặt

### Bước 1: Tạo Google Sheets Expense Log

Tạo Google Sheet với cấu trúc:

| date | merchant | amount | category | source |
|------|----------|--------|----------|--------|
| 2026-05-05 | Starbucks | 85000 | coffee | Email |
| 2026-05-05 | Shopee | 250000 | shopping | Email |
| 2026-05-04 | Grab | 45000 | transport | Email |

**Lấy Sheet ID:**
```
URL: https://docs.google.com/spreadsheets/d/SHEET_ID/edit
                                                   ↑
                                         Copy phần này
```

### Bước 2: Customize Bank Email Patterns

Mở node "Parse Transaction Data" và cập nhật regex patterns theo ngân hàng của bạn:

```javascript
// Vietcombank
const vcbPatterns = {
  amount: /Số tiền giao dịch:\s*([\d,]+)\s*VND/,
  merchant: /Tại đơn vị:\s*(.+?)(?:\n|$)/,
  date: /Thời gian giao dịch:\s*(\d{2}\/\d{2}\/\d{4})/
};

// Techcombank
const tcbPatterns = {
  amount: /Số tiền:\s*([\d,]+)\s*(?:VND|₫)/,
  merchant: /Nội dung:\s*(.+?)(?:\n|$)/,
  date: /Ngày:\s*(\d{2}-\d{2}-\d{4})/
};
```

### Bước 3: Customize Categories

Mở node "Categorize Expense" và cập nhật merchant mapping:

```javascript
const categories = {
  // Coffee/Tea
  'starbucks': 'coffee',
  'highlands': 'coffee',
  'trung nguyen': 'coffee',
  'phuc long': 'coffee',
  
  // Shopping
  'shopee': 'shopping',
  'lazada': 'shopping',
  'tiki': 'shopping',
  
  // Transport
  'grab': 'transport',
  'be': 'transport',
  'gojek': 'transport',
  
  // Food
  'now': 'food',
  'shopeefood': 'food',
  'foody': 'food',
  
  // Bills
  'evn': 'bills',
  'vnpt': 'bills',
  'viettel': 'bills'
};
```

### Bước 4: Cấu hình Monthly Budget

Mở node "IF: Budget Exceeded?" và set budgets:

```javascript
const monthlyBudgets = {
  coffee: 500000,      // 500k/tháng
  shopping: 2000000,   // 2 triệu/tháng
  transport: 1000000,  // 1 triệu/tháng
  food: 3000000,       // 3 triệu/tháng
  bills: 2000000,      // 2 triệu/tháng
  other: 1000000       // 1 triệu/tháng
};
```

### Bước 5: Chuẩn bị Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail → Connect |
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |
| **Telegram Bot** (Optional) | @BotFather → Create bot → Copy token |

### Bước 6: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/personal/03-expense-tracker/workflow.json`
4. Click **Import**

### Bước 7: Cấu hình Nodes

**1. Gmail Trigger:**
- Set **Poll Interval** = Every 5 minutes
- Filter emails từ ngân hàng (ví dụ: `from:ecf@vietcombank.com.vn`)
- Gán Gmail credential

**2. Log to Google Sheets:**
- Set **Document ID** = Sheet ID của bạn
- Set **Sheet Name** = tên sheet

**3. Telegram Alert (Optional):**
- Set **Chat ID** = chat ID của bạn
- Gán Telegram credential

### Bước 8: Test

1. Forward thử một email sao kê từ ngân hàng
2. Hoặc dùng email mẫu với format giống thật
3. Kiểm tra:
   - ✅ Transaction được parse đúng không?
   - ✅ Category được gán đúng không?
   - ✅ Google Sheets có row mới không?
   - ✅ Alert có gửi nếu vượt budget không?
4. Nếu OK → **Activate** workflow

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Không parse được email | Regex không khớp | Update patterns trong Code node |
| Category sai | Merchant không trong list | Thêm merchant vào categories |
| Email không trigger | Filter sai | Kiểm tra email filter trong trigger |
| Sheet không update | Sheet ID sai | Kiểm tra lại URL Google Sheets |

## ⚠️ Lưu ý Community Version

- ✅ **Gmail trigger** có sẵn, hoạt động tốt
- ✅ **Code node** parse regex hoàn toàn trong community
- ⚠️ **Mỗi ngân hàng có email format khác nhau** - cần customize regex
- 💡 **Tip**: Bắt đầu với 1 ngân hàng, test kỹ, sau đó thêm ngân hàng khác

## Mở rộng

### Thêm Multiple Bank Support
Parse emails từ nhiều ngân hàng:
```javascript
const bankPatterns = {
  vietcombank: vcbPatterns,
  techcombank: tcbPatterns,
  vpbank: vpbankPatterns
};

// Detect bank from sender email
const bank = detectBank(email.from);
const pattern = bankPatterns[bank];
```

### Thêm Monthly Report
Tạo báo cáo cuối tháng:
```
Schedule (Last day of month) → Query Sheets → Generate report → Send email
```

### Thêm Budget Recommendations
AI đề xuất giảm chi tiêu:
```javascript
if (spent > budget * 0.8) {
  recommendations.push(`⚠️ Bạn đã dùng 80% ngân sách ${category}`);
}
```
