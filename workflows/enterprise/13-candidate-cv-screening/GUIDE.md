# Google Form CV Screening with DeepSeek

Workflow cho n8n Community để xử lý ứng viên từ Google Form:

1. Ứng viên gửi thông tin và upload CV PDF/DOCX qua Google Form.
2. Google Form ghi response vào Google Sheets.
3. n8n polling row mới bằng Google Sheets Trigger.
4. Workflow lấy link CV, convert file sang Google Docs, export text.
5. DeepSeek đánh giá ứng viên dựa trên CV + JD tuyển dụng.
6. Lưu phân tích vào Google Sheets tracking.
7. Nếu ứng viên `excellent`, gửi thông báo Telegram cho HR.

## Files

| File | Mục đích |
|---|---|
| `workflow.json` | Workflow import vào n8n |
| `jd_frontend_react.example.txt` | JD mẫu để test |
| `demo-cv/` | 3 CV demo: excellent, good, average |

## Google Form Cần Có

Tạo Google Form với các câu hỏi:

| Câu hỏi | Type | Bắt buộc |
|---|---|---|
| `Họ và tên` | Short answer | Có |
| `Email` | Short answer / Email | Có |
| `Số điện thoại` | Short answer | Không |
| `Vị trí ứng tuyển` | Short answer | Có |
| `CV` | File upload | Có |
| `Nguồn ứng viên` | Short answer / Dropdown | Không |
| `JD tuyển dụng` | Paragraph | Không |

Nếu không muốn nhập JD trong từng form response, tạo n8n variable:

```text
Settings -> Variables -> Add Variable
Name: RECRUITMENT_JD_TEXT
Value: nội dung JD tuyển dụng
```

## Tracking Sheet

Tạo Google Sheet riêng, sheet tab tên:

```text
Candidate Tracking
```

Header row:

```text
Candidate ID, Received At, Name, Email, Phone, Position, Source, CV URL, Score, Classification, Recommendation, Summary, Strengths, Weaknesses, Matched Requirements, Missing Requirements, Risk Flags, Interview Questions, Next Step, Reasoning, AI Raw JSON, Processed At
```

## Credentials

### Google Sheets Trigger

Dùng cho node:

- `📥 Google Sheets Trigger: Form Ứng Viên`

Credential type:

```text
Google Sheets Trigger OAuth2 API
```

### Google Sheets

Dùng cho node:

- `📊 Google Sheets: Lưu Tracking Ứng Viên`

Credential type:

```text
Google Sheets OAuth2 API
```

### Google Drive

Dùng cho:

- `📄 Drive: Convert CV Sang Google Doc`
- `🧾 Drive: Export CV Text`

Credential type:

```text
Google Drive OAuth2 API
```

Google Drive credential phải có quyền đọc file CV upload từ Form. Cách dễ nhất là dùng cùng Google account sở hữu Form.

### DeepSeek

Tạo credential:

```text
Credentials -> Add credential -> Header Auth
Name: Authorization
Value: Bearer YOUR_DEEPSEEK_API_KEY
```

Dùng cho node:

- `🤖 DeepSeek: Đánh Giá Ứng Viên`

### Telegram

Tạo bot bằng `@BotFather`, sau đó tạo credential:

```text
Credentials -> Add credential -> Telegram API
```

Tạo n8n variable:

```text
Name: HR_TELEGRAM_CHAT_ID
Value: chat id của HR/group Telegram
```

## Import Workflow

1. Import `workflow.json`.
2. Mở node `📥 Google Sheets Trigger: Form Ứng Viên`.
3. Chọn Google Sheet đang nhận Google Form responses.
4. Mở node `📊 Google Sheets: Lưu Tracking Ứng Viên`.
5. Chọn Google Sheet tracking ứng viên.
6. Gán credentials Google Sheets, Google Drive, DeepSeek, Telegram.
7. Test bằng 3 CV demo trong `demo-cv/`.
8. Nếu ổn, bật `Active`.

## CV Demo

Folder `demo-cv/` có 3 CV demo để upload vào Google Form:

- `cv_nguyen_minh_anh_excellent.pdf`
- `cv_tran_quang_huy_good.docx`
- `cv_le_thu_linh_average.pdf`

Các file `.txt` cùng tên là source text để đọc/sửa nội dung demo khi cần.

## Lưu Ý Kỹ Thuật

Workflow dùng Google Drive conversion:

```text
PDF/DOCX -> Google Docs -> text/plain
```

Ưu điểm:

- Chạy được trên n8n Community.
- Không cần parser PDF/DOCX custom trong Code node.
- Không cần cài package ngoài container.

Giới hạn:

- PDF scan ảnh có thể trích text kém nếu OCR không nhận tốt.
- File CV cần Google Drive credential có quyền đọc.
- CV quá dài sẽ bị cắt ở 60.000 ký tự để tránh vượt context/token.

## Classification

DeepSeek trả về:

| Classification | Điều kiện |
|---|---|
| `excellent` | Score >= 85, match JD rất mạnh |
| `good` | Score 70-84 |
| `average` | Score 50-69 |
| `reject` | Score < 50 |

Telegram chỉ gửi khi:

```text
classification = excellent
```

hoặc:

```text
score >= 85
```
