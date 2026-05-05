# 📦 Enterprise: Order Fulfillment

## Mục tiêu
Tự động hóa **quy trình xử lý đơn hàng** e-commerce:
- Validate đơn hàng mới
- Kiểm tra tồn kho
- Gửi email xác nhận cho khách
- Thông báo cho kho đóng hàng
- Lưu đơn hàng vào Google Sheets để theo dõi

## Đối tượng sử dụng
**Doanh nghiệp** - Online stores, Shopify merchants, bất kỳ ai bán hàng online.

## Sơ đồ luồng
```
[Webhook: POST /webhook/new-order]
         │
         ▼
[Validate Order Data]
  (Email, phone, total)
         │
         ▼
[Check Inventory]
  (Google Sheets)
         │
    ┌────┴────┐
    ▼         ▼
[IF: In Stock?]
    │ yes     │ no
    ▼         ▼
[Send      [Send Out of
 Confirm   Stock Email]
 Email]
    │
    ▼
[Notify Warehouse]
  (Slack)
    │
    ▼
[Log to Google Sheets]
    │
    ▼
[Return Success Response]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Webhook (New Order) | Webhook | POST /webhook/new-order | None |
| Validate Order Data | Code | Validation logic | None |
| Check Inventory | Google Sheets | Search by product | Google Sheets OAuth2 |
| IF: In Stock? | IF | Check if results > 0 | None |
| Send Order Confirmation | Gmail | Vietnamese template | Gmail OAuth2 |
| Notify Warehouse | Slack | Message to #orders | Slack OAuth2 |
| Log Order to Sheets | Google Sheets | Append row | Google Sheets OAuth2 |
| Send Out of Stock | Gmail | Out of stock template | Gmail OAuth2 |
| Return Response | Respond to Webhook | JSON response | None |

## Cài đặt

### Bước 1: Tạo Google Sheets Inventory

Tạo Google Sheet quản lý tồn kho:

| product_name | sku | stock | price | category |
|--------------|-----|-------|-------|----------|
| Áo thun nam M | ATN-M | 50 | 150000 | Clothing |
| Áo thun nam L | ATN-L | 30 | 150000 | Clothing |
| Quần jean 30 | QJ-30 | 20 | 350000 | Clothing |

Tạo Google Sheet lưu đơn hàng:

| order_id | customer_name | customer_email | customer_phone | items | total | payment_method | status | created_at |
|----------|--------------|----------------|----------------|-------|-------|----------------|--------|------------|
| ORD-123 | Nguyễn Văn A | a@email.com | 0901234567 | Áo thun M x2 | 300000 | COD | confirmed | 2026-05-05 |

### Bước 2: Cấu hình Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect (cho cả 2 sheets) |
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail → Connect |
| **Slack OAuth2** | Settings → Credentials → Add → Slack → Connect |

### Bước 3: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/enterprise/03-order-fulfillment/workflow.json`
4. Click **Import**

### Bước 4: Cấu hình Nodes

**1. Check Inventory:**
- Set **Document ID** = Sheet ID của inventory sheet
- Set **Sheet Name** = tên sheet inventory

**2. Send Order Confirmation Email:**
- Review template email, customize theo brand của bạn
- Gmail credential đã được gán

**3. Notify Warehouse (Slack):**
- Set **Channel** = `#orders` (hoặc channel của bạn)
- Customize message format

**4. Log Order to Google Sheets:**
- Set **Document ID** = Sheet ID của orders sheet
- Set **Sheet Name** = tên sheet orders

**5. Send Out of Stock Email:**
- Review template, customize nếu cần

### Bước 5: Test

**Test bằng curl:**
```bash
curl -X POST https://your-n8n.com/webhook/new-order \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "ORD-001",
    "customer": {
      "name": "Nguyễn Văn A",
      "email": "nguyenvana@email.com",
      "phone": "0901234567",
      "address": "123 Đường ABC, Quận 1, TP.HCM"
    },
    "items": [
      {"product": "Áo thun nam M", "qty": 2, "price": 150000}
    ],
    "total": 300000,
    "payment_method": "COD"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Order processed successfully",
  "order_id": "ORD-001",
  "status": "confirmed",
  "total": 300000
}
```

**Kiểm tra:**
1. ✅ Google Sheets inventory có được check không?
2. ✅ Email xác nhận đã gửi cho khách?
3. ✅ Slack #orders có message không?
4. ✅ Đơn hàng đã được lưu vào orders sheet?
5. ✅ Response trả về đúng không?

## Cấu trúc dữ liệu

### Input (Webhook Body)
```json
{
  "order_id": "ORD-001",
  "customer": {
    "name": "Nguyễn Văn A",
    "email": "nguyenvana@email.com",
    "phone": "0901234567",
    "address": "123 Đường ABC, Quận 1, TP.HCM"
  },
  "items": [
    {"product": "Áo thun nam M", "qty": 2, "price": 150000}
  ],
  "total": 300000,
  "payment_method": "COD"
}
```

### Fields
| Field | Required | Format | Notes |
|-------|----------|--------|-------|
| order_id | ✅ | String | Mã đơn hàng duy nhất |
| customer.name | ✅ | String | Tên khách hàng |
| customer.email | ✅ | Email | Email xác nhận |
| customer.phone | ❌ | VN phone | 0XXXXXXXXX hoặc +84XXXXXXXXX |
| customer.address | ❌ | String | Địa chỉ giao hàng |
| items | ✅ | Array | Danh sách sản phẩm |
| items[].product | ✅ | String | Tên sản phẩm (phải khớp với inventory) |
| items[].qty | ❌ | Number | Số lượng (default: 1) |
| items[].price | ❌ | Number | Đơn giá VND |
| total | ❌ | Number | Tổng tiền (tự tính nếu không có) |
| payment_method | ❌ | String | COD, Bank Transfer, MoMo, v.v. |

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Webhook 404 | URL sai hoặc workflow chưa active | Kiểm tra URL và bật workflow |
| Không check được inventory | Sheet ID sai | Kiểm tra Sheet ID của inventory |
| Email không gửi được | Gmail credential invalid | Reconnect Gmail OAuth2 |
| Slack không gửi | Channel không tồn tại | Tạo channel `#orders` hoặc đổi tên |
| Product not found | Tên sản phẩm không khớp inventory | Kiểm tra chính tả tên sản phẩm |

## ⚠️ Lưu ý Community Version

- ✅ **Webhook node** hoạt động tốt
- ✅ **Google Sheets node** có sẵn
- ✅ **Gmail/Slack nodes** có sẵn
- ⚠️ **OAuth2 credentials** cần reconnect định kỳ
- ⚠️ **Queue mode không available** — nếu có nhiều orders cùng lúc, có thể chậm
- 💡 **Tip**: Với shop lớn (>100 orders/day), nên chuyển sang PostgreSQL thay vì Google Sheets

## Mở rộng

### Thêm Shopify Integration
Thay vì webhook, dùng Shopify trigger:
```
Shopify Trigger (New Order) → Validate → (rest of workflow)
```

### Thêm Shipping API (Giao Hàng Nhanh)
Tự động tạo đơn vận chuyển:
```javascript
// Sau khi confirm order
const shipping = await fetch('https://api.giaohangnhanh.vn/v2/order/create', {
  method: 'POST',
  headers: { 'Token': 'YOUR_TOKEN' },
  body: JSON.stringify({
    to_name: customer.name,
    to_phone: customer.phone,
    to_address: customer.address,
    items: order.items
  })
});
```

### Thêm Payment Verification (MoMo/VNPay)
Xác nhận thanh toán trước khi xử lý:
```
Webhook → Check Payment Status → IF paid → Process order
```

### Thêm Inventory Auto-Update
Tự động trừ tồn kho sau khi order:
```
Log Order → Update Inventory (stock = stock - qty)
```

### Integration với Website

**HTML Checkout Form:**
```html
<form action="https://your-n8n.com/webhook/new-order" method="POST">
  <!-- Customer info -->
  <input name="customer[name]" required>
  <input name="customer[email]" type="email" required>
  <input name="customer[phone]" required>
  <textarea name="customer[address]" required></textarea>
  
  <!-- Cart items (hidden, populated by JS) -->
  <input type="hidden" name="items" id="cart-items">
  <input type="hidden" name="total" id="cart-total">
  
  <button type="submit">Đặt hàng</button>
</form>
```
