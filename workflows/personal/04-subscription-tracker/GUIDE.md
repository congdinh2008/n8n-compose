# 💳 Personal: Subscription Tracker

## Mục tiêu
Tự động theo dõi **subscriptions** (Netflix, Spotify, Adobe, v.v.):
- Đọc danh sách subscriptions từ Google Sheets
- Lọc subscriptions cần thanh toán trong 7 ngày tới
- Gửi notification qua Telegram/Email
- Giúp bạn không bỏ lỡ payments và hủy subscriptions không cần thiết

## Đối tượng sử dụng
**Cá nhân** - Bất kỳ ai có multiple subscriptions và muốn track chi phí hàng tháng.

## Sơ đồ luồng
```
[Schedule Trigger (Monthly)]
         │
         ▼
[Read Subscription List (Google Sheets)]
         │
         ▼
[Filter Due Subscriptions (next 7 days)]
         │
         ▼
[IF: Has Due Subscriptions?]
    │ true
    ▼
[Format Notification]
    │
    ├─────────────┐
    ▼             ▼
[Telegram]    [Email]
 Notification  Notification
```

## Cài đặt

### Bước 1: Tạo Google Sheets Subscription List

| service | amount | billing_date | category | status |
|---------|--------|--------------|----------|--------|
| Netflix | 260000 | 15 | Entertainment | active |
| Spotify | 59000 | 5 | Music | active |
| Adobe CC | 549000 | 20 | Software | active |
| iCloud 50GB | 25000 | 10 | Storage | active |

**billing_date:** Ngày trong tháng mà service sẽ bill (1-31)

### Bước 2-5: Xem GUIDE.md trong thư mục workflow

(Các bước tương tự các workflows khác)

## ⚠️ Lưu ý Community Version
- ✅ Tất cả nodes đều có sẵn trong community
- ⚠️ Google Sheets OAuth cần reconnect định kỳ
- 💡 **Tip**: Review subscriptions hàng tháng và hủy cái không dùng
