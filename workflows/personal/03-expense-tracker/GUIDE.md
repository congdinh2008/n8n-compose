# 💰 Personal: Expense Tracker

## Mục tiêu
Tự động **theo dõi chi tiêu cá nhân** từ email thông báo giao dịch ngân hàng:
- Parse thông tin giao dịch từ email (số tiền, merchant, ngày)
- Tự động phân loại chi tiêu (cà phê, mua sắm, di chuyển, v.v.)
- Log vào Google Sheets để theo dõi
- Cảnh báo khi vượt quá ngân sách hàng tháng

## Đối tượng sử dụng
**Cá nhân** - Bất kỳ ai muốn tự động theo dõi chi tiêu hàng ngày mà không cần nhập thủ công.

## Sơ đồ luồng
```
[Gmail Trigger (Bank Emails)]
         │
         ▼
[Parse Transaction Data]
  (Regex extraction từ email)
         │
         ▼
[Categorize Expense]
  (Merchant → Category mapping)
         │
         ▼
[Log to Google Sheets]
         │
         ▼
    IF: Budget Exceeded?
    │          │
    Yes        No
    │          │
    ▼          ▼
[Telegram   [Log Silent]
 Alert]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Gmail Trigger | Gmail | Filter: bank email addresses | Gmail OAuth2 |
| Parse Transaction Data | Code | Regex cho VND, date, merchant | None |
| Categorize Expense | Code | Merchant → Category mapping | None |
| Log to Google Sheets | Google Sheets | Append row | Google Sheets OAuth2 |
| IF: Budget Exceeded? | IF | Check % of monthly budget | None |
| Send Telegram Alert | Telegram | Budget exceeded warning | Telegram Bot Token |

## Cài đặt

### Bước 1: Cấu hình Gmail Trigger

Mở node "Gmail Trigger (Bank Emails)" và set **from filter** với các email ngân hàng:

```
vietcombank: noreply@vietcombank.com.vn
techcombank: alert@techcombank.com.vn
vpbank: notifications@vpbank.com.vn
mbbank: contact@mbbank.com.vn
bidv: customer@bidv.com.vn
agribank: customercare@agribank.com.vn
acb: notification@acb.com.vn
tpbank: donotreply@tpb.vn
vib: noreply@vib.com.vn
shb: notification@shb.com.vn
```

### Bước 2: Chuẩn bị Google Sheets

Tạo Google Sheet với các columns:

| date | merchant | amount | category | type | email_from | parsed_at |
|------|----------|--------|----------|------|------------|-----------|
| 2026-05-05 | Highlands Coffee | 45,000 | Cà phê/Trà sữa | purchase | noreply@... | 2026-05-05T... |

**Lấy Sheet ID:**
```
URL: https://docs.google.com/spreadsheets/d/SHEET_ID/edit
                                                   ↑
                                         Copy phần này
```

### Bước 3: Cấu hình Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail OAuth2 → Connect |
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |
| **Telegram Bot** (Optional) | Tạo bot qua @BotFather → Copy token → Add credentials |

### Bước 4: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/personal/03-expense-tracker/workflow.json`
4. Click **Import**

### Bước 5: Cấu hình Nodes

**1. Log to Google Sheets:**
- Mở node "Log to Google Sheets"
- Set **Document ID** = Sheet ID của bạn
- Set **Sheet Name** = tên sheet (thường là "Sheet1")

**2. Customize Budgets:**
- Mở node "Categorize Expense"
- Điều chỉnh ngân sách hàng tháng trong code:
```javascript
const monthlyBudgets = {
  coffee: 1000000,      // 1 triệu - Điều chỉnh theo nhu cầu
  shopping: 5000000,    // 5 triệu
  transport: 2000000,   // 2 triệu
  food: 3000000,        // 3 triệu
  bills: 2000000,       // 2 triệu
  entertainment: 1000000,
  health: 5000000,
  education: 3000000,
  other: 2000000
};
```

**3. Customize Categories:**
- Trong cùng node "Categorize Expense"
- Thêm merchant vào categories:
```javascript
const categories = {
  coffee: ['starbucks', 'highlands', 'trung nguyen', /* thêm merchant */],
  shopping: ['shopee', 'lazada', 'tiki', /* thêm merchant */],
  // ...
};
```

**4. Send Telegram Alert (Optional):**
- Set **Chat ID** = chat ID của bạn
- Gán Telegram credential
- **Hoặc xóa node này** nếu không dùng Telegram

### Bước 6: Test

1. Đợi email ngân hàng thật đến HOẶC gửi email test với nội dung giao dịch
2. Click **Test Workflow**
3. Kiểm tra:
   - ✅ Số tiền được parse đúng không?
   - ✅ Merchant được nhận diện đúng không?
   - ✅ Category được gán đúng không?
   - ✅ Google Sheets có row mới không?
   - ✅ Telegram alert có gửi nếu vượt budget không?

## Email Patterns Supported

### Vietnamese Bank Email Formats

**Vietcombank:**
```
Số tiền giao dịch: 1,234,567 VND
tại: SHOPEE VN
Thời gian: 05/05/2026 14:30
```

**Techcombank:**
```
GD: 1.234.567đ
Nội dung: Thanh toan don hang
 Merchant: TIKI
```

**MB Bank:**
```
So tien: 500,000 VND
Ten Don vi: GRAB
Thoi gian: 2026-05-05T14:30:00
```

### Regex Patterns Used
- Amount: `/([\d\.,]+)\s*(?:[Vv][Nn][Dd]|[₫đ])/`
- Merchant: `/(?:tại|ở|TẠI|Ở)\s+([^\n,.]+)/`
- Date: `/(\d{2})\/(\d{2})\/(\d{4})\s+(\d{2}:\d{2})/`

## Category Mapping

| Category | Merchants | Monthly Budget (default) |
|----------|-----------|--------------------------|
| Cà phê/Trà sữa | Starbucks, Highlands, Trung Nguyen, Phuc Long | 1,000,000đ |
| Mua sắm | Shopee, Lazada, Tiki, Aeon, Lotte | 5,000,000đ |
| Di chuyển | Grab, Be, Gojek, Uber, Taxi | 2,000,000đ |
| Ăn uống | Now, ShopeeFood, Foody | 3,000,000đ |
| Hóa đơn | EVN, VNPT, Viettel, FPT | 2,000,000đ |
| Giải trí | Netflix, Spotify, YouTube Premium | 1,000,000đ |
| Sức khỏe | Nhà thuốc, Bệnh viện, Phòng khám | 5,000,000đ |
| Giáo dục | VnEdu, Coursera, Udemy | 3,000,000đ |
| Khác | Everything else | 2,000,000đ |

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Không parse được số tiền | Email format không match regex | Kiểm tra email mẫu và update regex trong Code node |
| Merchant không nhận diện | Tên merchant không có trong list | Thêm merchant vào categories trong Code node |
| Google Sheets error | Sheet ID sai hoặc credential hết hạn | Kiểm tra Sheet ID và reconnect OAuth |
| Không có alert khi vượt budget | Budget configuration sai | Kiểm tra monthlyBudgets trong Code node |
| Telegram không gửi được | Bot token hoặc chat_id sai | Kiểm tra credentials |

## ⚠️ Lưu ý Community Version

- ✅ **Gmail node** có sẵn, chỉ cần OAuth2
- ✅ **Google Sheets node** có sẵn
- ⚠️ **Email parsing** depends on bank email format - có thể cần customize regex
- ⚠️ **OAuth2 credentials** cần reconnect định kỳ
- 💡 **Tip**: Test với email thật từ ngân hàng của bạn trước khi dùng production

## Mở rộng

### Thêm Monthly Report
Tạo workflow riêng chạy ngày 1 hàng tháng:
```
Schedule (monthly) → Read Google Sheets → Calculate totals → Send report email
```

### Thêm Budget Top-up Notifications
Gửi reminder khi đạt 80% budget:
```javascript
if (budgetPercentage >= 80 && budgetPercentage < 100) {
  // Gửi warning thay vì alert
  message = `⚠️ Bạn đã sử dụng ${budgetPercentage}% ngân sách ${category_vn}`;
}
```

### Thêm Income Tracking
Theo dõi thu nhập để tính savings rate:
```javascript
if (transaction.type === 'deposit') {
  category = 'income';
  // Log vào sheet riêng
}
```

### Tích hợp với MoMo/ZaloPay
Dùng HTTP Request node để lấy giao dịch từ ví điện tử:
```javascript
const momoTransactions = await fetch('https://api.momo.vn/v1/transactions', {
  headers: { 'Authorization': 'Bearer YOUR_TOKEN' }
});
```
