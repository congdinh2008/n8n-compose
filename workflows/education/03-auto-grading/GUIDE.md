# 🎓 Education: Auto Grading

## Mục tiêu
Tự động **chấm điểm bài kiểm tra trắc nghiệm** từ Google Form:
- Đọc đáp án từ answer key
- So sánh với bài làm học sinh
- Tính điểm thang 10
- Xếp loại (Giỏi, Khá, Trung bình, Yếu)
- Gửi email kết quả cho học sinh
- Notify giáo viên qua Telegram

## Đối tượng sử dụng
**Giáo viên** - Dạy học online, kiểm tra trắc nghiệm, quizzes.

## Sơ đồ luồng
```
[Google Sheets Trigger - Form Responses]
         │
         ▼
[Auto Grade (Chấm điểm)]
  (Compare with answer key)
         │
         ▼
[Save Grades to Sheet]
  (Google Sheets - Bảng điểm)
         │
    ┌────┴────┐
    ▼         ▼
[Email    [Notify Teacher
Student]  via Telegram]
```

## Nodes chi tiết

| Node | Type | Configuration | Credentials |
|------|------|---------------|-------------|
| Google Sheets Trigger | Sheets Trigger | Poll every minute | Google Sheets OAuth2 |
| Auto Grade | Code | Answer key comparison | None |
| Save Grades | Google Sheets | Append row | Google Sheets OAuth2 |
| Email Student | Gmail | Result template | Gmail OAuth2 |
| Notify Teacher | Telegram | Score notification | Telegram Bot Token |

## Cài đặt

### Bước 1: Tạo Google Form Quiz

1. Tạo Google Form với câu hỏi trắc nghiệm
2. Questions đặt tên: `Câu 1`, `Câu 2`, ..., `Câu 10`
3. Link form responses vào Google Sheets

### Bước 2: Cập nhật Answer Key

Mở node "Auto Grade (Chấm điểm tự động)" và cập nhật đáp án:

```javascript
const answerKey = {
  'Câu 1': 'A',
  'Câu 2': 'B',
  'Câu 3': 'C',
  'Câu 4': 'D',
  'Câu 5': 'A',
  'Câu 6': 'B',
  'Câu 7': 'C',
  'Câu 8': 'A',
  'Câu 9': 'D',
  'Câu 10': 'B'
};
```

### Bước 3: Tạo Google Sheets Bảng điểm

| student_name | student_email | score | percentage | correct_count | total_questions | grade | graded_at |
|--------------|--------------|-------|------------|---------------|-----------------|-------|-----------|
| Nguyễn Văn A | a@email.com | 8.50 | 85.0 | 9 | 10 | Giỏi | 2026-05-05 |

### Bước 4: Cấu hình Credentials

| Credential | Hướng dẫn |
|-----------|-----------|
| **Google Sheets OAuth2** | Settings → Credentials → Add → Google Sheets → Connect |
| **Gmail OAuth2** | Settings → Credentials → Add → Gmail → Connect |
| **Telegram Bot** | @BotFather → Create bot → Copy token |

### Bước 5: Import Workflow

1. Mở n8n Dashboard
2. **Add Workflow** → **Import from File**
3. Chọn: `workflows/education/03-auto-grading/workflow.json`
4. Click **Import**

### Bước 6: Cấu hình Nodes

**1. Google Sheets Trigger:**
- Set **Document ID** = Sheet ID của Form Responses
- Set **Sheet Name** = `Form Responses 1`

**2. Save Grades:**
- Set **Document ID** = Sheet ID của Bảng điểm sheet
- Set **Sheet Name** = tên sheet

**3. Email Student:**
- Gán Gmail credential
- Email template đã có sẵn tiếng Việt

**4. Notify Teacher:**
- Set **Chat ID** = chat ID của giáo viên
- Gán Telegram credential

### Bước 7: Test

1. Điền form test với đáp án đúng/sai
2. Kiểm tra:
   - ✅ Điểm tính đúng không?
   - ✅ Email học sinh nhận được?
   - ✅ Telegram teacher notification?
   - ✅ Bảng điểm sheet có row mới?
3. Nếu OK → **Activate** workflow

## Grading Scale

| Điểm | Xếp loại |
|------|----------|
| 9.0 - 10.0 | Giỏi |
| 8.0 - 8.9 | Khá |
| 6.5 - 7.9 | Trung bình khá |
| 5.0 - 6.4 | Trung bình |
| 0.0 - 4.9 | Yếu |

## ⚠️ Lưu ý Community Version

- ✅ **Google Sheets Trigger** có sẵn
- ✅ **Code node** cho grading logic hoạt động tốt
- ⚠️ **OAuth2 credentials** cần reconnect định kỳ
- 💡 **Tip**: Có thể thêm multiple-choice form validation trước khi submit

## Mở rộng

### Thêm Time Limit
Theo dõi thời gian làm bài:
```javascript
const startTime = new Date(submission['Timestamp']);
const endTime = new Date();
const duration = (endTime - startTime) / 60000; // minutes
```

### Thêm Question Analysis
Phân tích độ khó câu hỏi:
```
All submissions → Calculate % correct per question → Identify hard questions
```

### Thêm Parent Notification
Gửi kết quả cho phụ huynh:
```
Grade saved → Send email to parent_email (if available)
```

### Thêm Leaderboard
Bảng xếp hạng lớp:
```
Weekly schedule → Calculate top scores → Post to Google Sheets/Slack
```
