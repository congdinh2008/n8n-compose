# 📦 Enterprise: Order Fulfillment

## Mục tiêu
Tự động hóa **xử lý đơn hàng e-commerce**:
- Nhận đơn hàng mới từ website/webhook
- Validate và kiểm tra tồn kho
- Gửi email xác nhận cho khách hàng
- Thông báo kho đóng hàng qua Slack
- Lưu đơn hàng vào Google Sheets để theo dõi
- Xử lý trường hợp hết hàng

## Đối tượng sử dụng
**Doanh nghiệp** - E-commerce teams, online stores, warehouses, bất kỳ ai cần xử lý đơn hàng tự động.

## Sơ đồ luồng
```
[Webhook: POST /webhook/new-order]
         │
         ▼
[Validate Order Data]
         │
         ▼
[Check Inventory (Google Sheets)]
         │
         ▼
    IF: In Stock?
    │          │
    Yes        No
    │          │
    ▼          ▼
[Send      [Send Out
 Confirm]   of Stock]
    │
    ▼
[Notify Warehouse (Slack)]
    │
    ▼
[Log Order to Google Sheets]
    │
    ▼
[Return Success Response]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Webhook (New Order) | Webhook | POST /webhook/new-order | None |
| Validate Order Data | Code | Validate + calculate total | None |
| Check Inventory | Google Sheets | Search by product name | Google Sheets OAuth2 |
| IF: In Stock? | IF | Check if inventory > 0 | None |
| Send Confirmation Email | Gmail | Order confirmation template | Gmail OAuth2 |
| Notify Warehouse | Slack | Order details to #orders | Slack OAuth2 |
| Log Order | Google Sheets | Append row | Google Sheets OAuth2 |
| Send Out of Stock Email | Gmail | Out of stock notification | Gmail OAuth2 |

## Cài đặt

### Bước 1: Cấu hình Webhook

**Webhook URL:** `https://your-n8n-domain.com/webhook/new-order`

**Request format:**
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
      { "product": "Áo thun nam", "qty": 2, "price": 150000 },
      { "product": "Quần jean", "qty": 1, "price": 350000 }
    ],
    "total": 650000,
    "payment_method": "COD"
  }'
```

### Bước 2: Chuẩn bị Google Sheets

**Sheet 1: Inventory**

| product_name | sku | stock | price |
|--------------|-----|-------|-------|
| Áo thun nam | TSHIRT-001 | 50 | 150,000 |
| Quần jean | JEANS-001 | 30 | 350,000 |

**Sheet 2: Orders**

| order_id | customer_name | customer_email | customer_phone | items | total | payment_method | status | created_at |
|----------|---------------|----------------|----------------|-------|-------|----------------|--------|------------|
| ORD-001 | Nguyễn A | a@email.com | 0901234567 | Áo thun x2, Quần x1 | 650000 | COD | confirmed | 2026-05-05 |

### Bước 3: Cấu hình Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail OAuth2 → Connect |
| **Slack OAuth2** | Settings → Credentials → Add → Slack OAuth2 → Connect |
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect (cho cả 2 sheets) |

### Bước 4: Tạo Slack Channel

Tạo channel `#orders` trong Slack để nhận thông báo đơn hàng mới.

### Bước 5: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/enterprise/03-order-fulfillment/workflow.json`
4. Click **Import**

### Bước 6: Cấu hình Nodes

**1. Check Inventory (Google Sheets):**
- Set **Document ID** = Sheet ID của Inventory sheet
- Set **Sheet Name** = tên sheet inventory
- Configure filter để search theo `product_name`

**2. Send Order Confirmation Email:**
- Review và customize template email
- Thêm logo công ty (nếu cần)
- Điều chỉnh thông tin giao hàng

**3. Notify Warehouse (Slack):**
- Set **Channel** = `#orders`
- Customize message format
- Gán Slack credential

**4. Log Order to Google Sheets:**
- Set **Document ID** = Sheet ID của Orders sheet
- Set **Sheet Name** = tên sheet orders

### Bước 7: Test

1. Gửi test order qua curl (xem Bước 1)
2. Kiểm tra:
   - ✅ Email xác nhận có đến khách hàng không?
   - ✅ Slack có message trong #orders không?
   - ✅ Google Sheets có row mới không?
   - ✅ Response trả về có đúng không?
3. Test out of stock scenario:
   - Set stock = 0 trong Inventory sheet
   - Gửi order → Kiểm tra email out of stock

## Order Data Structure

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
    { "product": "Product Name", "qty": 2, "price": 150000 }
  ],
  "total": 650000,
  "payment_method": "COD"
}
```

### Payment Methods (Vietnamese)
- **COD** - Cash on Delivery (Thanh toán khi nhận hàng)
- **Bank Transfer** - Chuyển khoản ngân hàng
- **MoMo** - Ví điện tử MoMo
- **VNPay** - Cổng thanh toán VNPay
- **ZaloPay** - Ví điện tử ZaloPay
- **Credit Card** - Thẻ tín dụng

### Order Status Flow
```
pending → confirmed → processing → shipped → delivered
                              ↓
                        out_of_stock
```

## Email Templates

### Order Confirmation Email
**Subject:** `Xác nhận đơn hàng #{{order_id}}`

**Nội dung:**
- Chào khách hàng
- Chi tiết đơn hàng
- Tổng tiền
- Địa chỉ giao hàng
- Thời gian giao hàng dự kiến (2-3 ngày)
- Contact info

### Out of Stock Email
**Subject:** `Thông báo hết hàng - Đơn hàng #{{order_id}}`

**Nội dung:**
- Xin lỗi khách hàng
- Giải thích sản phẩm hết hàng
- Offer alternatives (sản phẩm thay thế, hoàn tiền)
- Timeline sẽ có hàng lại

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| Webhook 404 | URL sai hoặc workflow chưa active | Kiểm tra URL và bật workflow |
| Không kiểm tra được tồn kho | Sheet ID sai | Kiểm tra Inventory sheet ID |
| Email không gửi | Gmail credential invalid | Reconnect Gmail OAuth2 |
| Slack không gửi | Channel #orders không tồn tại | Tạo channel trong Slack |
| Total tính sai | Items format sai | Kiểm tra items array trong request |
| Không log được order | Orders sheet ID sai | Kiểm tra Sheet ID và permissions |

## ⚠️ Lưu ý Community Version

- ✅ **Webhook node** hoạt động tốt
- ✅ **Gmail/Slack nodes** có sẵn
- ✅ **Google Sheets node** có sẵn
- ⚠️ **Inventory check** đơn giản - không handle concurrent orders tốt
- ⚠️ **Queue mode không available** — nếu nhận nhiều orders cùng lúc, có thể chậm
- 💡 **Tip**: Khi scale lên 100+ orders/ngày, chuyển sang database thật (PostgreSQL/MySQL)

## Mở rộng

### Tích hợp với Shopify
Thay vì webhook, dùng Shopify trigger:
```
Shopify Trigger (New Order) → Validate → Check Inventory → ...
```

### Thêm Shipping Integration
Tự động tạo shipping order:
```javascript
// Gửi request đến Giao Hàng Nhanh
const shipping = await fetch('https://api.giaohangnhanh.vn/orders', {
  method: 'POST',
  body: JSON.stringify({
    to_name: customer.name,
    to_phone: customer.phone,
    to_address: customer.address,
    items: order.items
  })
});
```

### Thêm Payment Verification
Xác nhận thanh toán trước khi xác nhận order:
```
Validate → Check Payment Status → IF: Paid? → Confirm Order
```

### Thêm Order Tracking
Gửi email tracking cho khách khi order được ship:
```
Shipping Created → Wait 1 day → Send Tracking Email
```

### Tích hợp với Website

**HTML Form:**
```html
<form action="https://your-n8n.com/webhook/new-order" method="POST">
  <input type="text" name="customer[name]" required>
  <input type="email" name="customer[email]" required>
  <input type="tel" name="customer[phone]">
  <textarea name="customer[address]" required></textarea>
  <!-- Items would be added dynamically via JS -->
  <button type="submit">Đặt hàng</button>
</form>
```

### Thêm Return/Refund Handling
Workflow riêng cho xử lý trả hàng:
```
Webhook (/return) → Validate Return → Update Inventory → Process Refund
```
