# 💰 Enterprise: Invoice Generation

## Mục tiêu
Tự động **tạo hóa đơn** cho các đơn hàng đã giao thành công:
- Tính VAT 10% theo quy định Việt Nam
- Lưu vào Google Sheets để theo dõi
- Gửi email hóa đơn cho khách hàng
- Đánh dấu order đã có hóa đơn (tránh trùng)

## Đối tượng sử dụng
**Finance/Accounting teams** - Phòng kế toán cần tạo hóa đơn tự động cho orders.

## Sơ đồ luồng
```
[Schedule Trigger - 5:00 PM Daily]
         │
         ▼
[Get Delivered Orders]
  (Status = delivered, no invoice)
         │
         ▼
[Generate Invoice Data]
  (Calculate VAT 10%)
         │
         ▼
[Save Invoices to Sheet]
         │
    ┌────┴────┐
    ▼         ▼
[Email    [Update Order
 Invoice]  (generated)]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Schedule Trigger | Schedule | Daily at 5:00 PM | None |
| Get Orders | Google Sheets | Filter by status | Google Sheets OAuth2 |
| Generate Invoice Data | Code | VAT calculation | None |
| Save Invoices | Google Sheets | Append row | Google Sheets OAuth2 |
| Email Invoice | Gmail | Vietnamese template | Gmail OAuth2 |
| Update Order | Google Sheets | Update row | Google Sheets OAuth2 |

## Cài đặt

### Bước 1: Tạo Google Sheets Invoices

| invoice_number | order_id | customer_name | customer_email | subtotal | vat_amount | total | invoice_date | status |
|----------------|----------|--------------|----------------|----------|------------|-------|--------------|--------|
| INV-123456-ABC | ORD-001 | Nguyễn Văn A | a@email.com | 1000000 | 100000 | 1100000 | 2026-05-05 | generated |

### Bước 2: Orders Sheet Requirements

Orders sheet cần có column:
- `status`: `delivered` (đã giao thành công)
- `invoice_generated`: `false` (chưa tạo), `true` (đã tạo)

### Bước 3: Update Company Information

Mở node "Generate Invoice Data" và cập nhật:

```javascript
company: {
  name: 'Tên Công Ty',
  address: 'Địa chỉ công ty',
  tax_id: 'Mã số thuế',
  phone: 'Số điện thoại',
  email: 'Email billing'
}
```

### Bước 4: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/enterprise/09-invoice-generation/workflow.json`
4. Click **Import**

### Bước 5: Configure Nodes

**1. Schedule Trigger:**
- Set **Rule**: `everyDay`
- Set **triggerAtHour**: `17` (5 PM)
- Set **triggerAtMinute**: `0`

**2. Get Orders:**
- Set **Document ID** = Sheet ID của orders sheet
- Set **Sheet Name** = tên sheet orders

**3. Save Invoices:**
- Set **Document ID** = Sheet ID của invoices sheet
- Set **Sheet Name** = tên sheet invoices

**4. Email Invoice:**
- Gmail credential đã được gán
- Review template, customize với company info

### Bước 6: Test

1. Thêm order vào orders sheet với:
   - `status` = `delivered`
   - `invoice_generated` = `false`
2. Click **Test Workflow**
3. Kiểm tra:
   - ✅ Invoice được tạo với VAT đúng không?
   - ✅ Invoices sheet có row mới không?
   - ✅ Email hóa đơn đã gửi cho khách?
   - ✅ Order được update `invoice_generated` = `true`?
4. Nếu OK → **Activate** workflow

## VAT Calculation

```javascript
// Vietnam VAT rate: 10%
const vatRate = 0.10;
const subtotal = order.total;
const vatAmount = subtotal * vatRate;
const totalWithVAT = subtotal + vatAmount;
```

## Invoice Template

```
Kính gửi [Customer Name],

📄 Hóa đơn của bạn đã được tạo!

Số hóa đơn: INV-XXXXX
Ngày tạo: 2026-05-05
Mã đơn hàng: ORD-001

📦 CHI TIẾT SẢN PHẨM:
[Items from order]

💰 THANH TOÁN:
Tạm tính: 1,000,000đ
VAT (10%): 100,000đ
━━━━━━━━━━━━━━━━━━━━
TỔNG TIỀN: 1,100,000đ

🏢 THÔNG TIN CÔNG TY:
Tên Công Ty
Địa chỉ: ...
Mã số thuế: ...
```

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Không lấy được orders | Sheet ID sai | Kiểm tra Sheet ID |
| VAT tính sai | Code logic error | Kiểm tra calculation trong Code node |
| Email không gửi | Gmail credential invalid | Reconnect Gmail OAuth2 |
| Hóa đơn trùng | Update order không chạy | Kiểm tra idColumn configuration |

## ⚠️ Lưu ý Community Version

- ✅ **Google Sheets nodes** có sẵn
- ✅ **Schedule trigger** hoạt động tốt
- ⚠️ **PDF generation** không có native node - cần external service
- 💡 **Tip**: Với PDF invoices, dùng HTTP Request đến dịch vụ tạo PDF

## Mở rộng

### Thêm PDF Generation
Tạo PDF invoice:
```javascript
// Dùng HTTP Request đến PDF generation service
const pdf = await fetch('https://api.pdflayer.com', {
  method: 'POST',
  body: JSON.stringify({ invoice_data })
});
// Attach PDF to email
```

### Thêm E-Invoice Integration
Kết nối với hệ thống hóa đơn điện tử:
```
Save Invoice → HTTP Request to Vietnam e-invoice API (MVN, Viettel, VNPT)
```

### Thêm Payment Reconciliation
Tự động đối soát thanh toán:
```
Schedule (daily) → Check bank statements → Match with invoices → Update payment status
```

### Thêm Monthly Report
Báo cáo hóa đơn hàng tháng:
```
Schedule (monthly) → Aggregate invoices → Calculate total revenue → Email finance team
```
