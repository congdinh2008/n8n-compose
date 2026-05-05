# 🎯 Personal: Habit Tracker

## Mục tiêu
Tự động theo dõi **thói quen hàng ngày** (habit tracking):
- Đọc habit list từ Google Sheets
- Check trạng thái mỗi habit (completed, at_risk, broken, not_started)
- Tính streaks (số ngày liên tiếp hoàn thành)
- Gửi báo cáo buổi tối qua Telegram
- Gửi email alert nếu có streaks bị đứt

## Đối tượng sử dụng
**Cá nhân** - Người muốn xây dựng thói quen tốt và theo dõi progress hàng ngày.

## Sơ đồ luồng
```
[Schedule Trigger (Daily 9 PM)]
         │
         ▼
[Read Habit Tracker Sheet]
         │
         ▼
[Check Habit Status]
  (completed/at_risk/broken)
         │
         ▼
[Format Evening Report]
  (Với motivational messages)
         │
    ┌────┴────┐
    ▼         ▼
[Telegram] [IF: High Urgency?]
 Report          │ true
                 ▼
          [Email Alert]
```

## Cài đặt

### Bước 1: Tạo Google Sheets Habit Tracker

| habit | target | completed | streak | last_completed |
|-------|--------|-----------|--------|----------------|
| Đọc sách | 30 phút/ngày | true | 15 | 2026-05-04 |
| Tập thể dục | 30 phút/ngày | false | 0 | 2026-05-02 |
| Thiền | 10 phút/ngày | true | 7 | 2026-05-04 |
| Viết journal | 1 trang/ngày | false | 0 | |

### Bước 2-5: Import và cấu hình

Xem chi tiết trong GUIDE.md của workflow.

## Habit Status Logic

| Status | Meaning | Action |
|--------|---------|--------|
| completed | Đã làm hôm nay | ✅ Giữ vững! |
| at_risk | Đã làm hôm qua, chưa làm hôm nay | ⚠️ Cần làm hôm nay! |
| broken | Streak bị đứt | ❌ Bắt đầu lại từ đầu |
| not_started | Chưa bao giờ làm | 📝 Hãy bắt đầu! |

## ⚠️ Lưu ý Community Version
- ✅ Wait/Schedule nodes hoạt động tốt
- ✅ Telegram và Gmail đều có sẵn
- 💡 **Tip**: Update sheet hàng ngày hoặc dùng webhook để mark complete

## Mở rộng

### Thêm Webhook để Mark Complete
Thay vì manual update sheet, tạo webhook:
```
POST /webhook/habit-complete { habit: "Đọc sách" }
→ Update Google Sheets (completed = true, streak++, last_completed = today)
```

### Thêm Streak Milestones
Notification khi đạt milestones:
```javascript
if (newStreak === 30) message += "🎉 30 ngày streak!";
if (newStreak === 100) message += "🏆 100 ngày streak!";
```
