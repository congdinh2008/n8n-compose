# Telegram AI Company Chatbot (n8n Community)

Workflow chatbot Telegram cho n8n Community:

1. User nhắn tin cho Telegram bot.
2. n8n nhận message bằng Telegram Trigger.
3. Workflow tải file JSON chứa quy trình công việc, sản phẩm, FAQ, chính sách công ty.
4. AI Agent dùng Gemini để tổng hợp câu trả lời dựa trên message + JSON.
5. Bot gửi câu trả lời lại đúng Telegram chat của user.

## File

| File | Mục đích |
|---|---|
| `workflow.json` | Import vào n8n |
| `company_knowledge.example.json` | File JSON mẫu để đưa lên Google Drive |

## Credentials Cần Có

### 1. Telegram Bot

Tạo bot bằng BotFather:

```text
/newbot
```

Copy bot token, vào n8n:

```text
Credentials -> Add credential -> Telegram API -> nhập token
```

Sau khi import workflow, chọn credential này cho:

- `📩 Telegram Trigger: Nhận Tin Nhắn`
- `📤 Telegram: Gửi Trả Lời`
- `📤 Telegram: Nhắc Gửi Text`

### 2. Google Drive OAuth2

Bật Google Drive API trong Google Cloud, rồi tạo OAuth2 credential trong n8n:

```text
Credentials -> Add credential -> Google Drive OAuth2 API
```

Credential này dùng cho node:

- `📚 Google Drive: Tải File JSON Công Ty`

### 3. Google Gemini API

Lấy API key ở Google AI Studio, rồi tạo credential:

```text
Credentials -> Add credential -> Google Gemini(PaLM) API
```

Credential này dùng cho node:

- `🤖 AI Agent: Gemini Trả Lời`

## Chuẩn Bị File JSON Công Ty

1. Mở `company_knowledge.example.json`.
2. Thay dữ liệu mẫu bằng quy trình, sản phẩm, FAQ, chính sách thật.
3. Upload file JSON lên Google Drive.
4. Lấy File ID từ URL.

Ví dụ URL:

```text
https://drive.google.com/file/d/1AbCdEfGhIjKlMnOpQrStUvWxYz/view
```

File ID là:

```text
1AbCdEfGhIjKlMnOpQrStUvWxYz
```

Trong n8n, tạo variable:

```text
Settings -> Variables -> Add Variable
Name: COMPANY_KNOWLEDGE_FILE_ID
Value: 1AbCdEfGhIjKlMnOpQrStUvWxYz
```

## Import Workflow

```text
n8n -> Workflows -> Import from File -> chọn workflow.json
```

Sau khi import:

1. Gán Telegram credential cho các node Telegram.
2. Gán Google Drive credential cho node tải JSON.
3. Gán Gemini credential cho node AI Agent.
4. Kiểm tra biến `COMPANY_KNOWLEDGE_FILE_ID`.
5. Bấm `Test workflow`, nhắn tin cho bot Telegram.
6. Nếu chạy ổn, bật `Active`.

## Lưu Ý Cho n8n Community

Workflow này chỉ dùng node có trong n8n Community/self-hosted:

- Telegram Trigger
- Telegram
- HTTP Request
- Code
- IF

Không dùng queue mode, RBAC, workflow history nâng cao, vector database hay tính năng Enterprise.

## Gợi Ý Câu Hỏi Test

```text
Công ty có sản phẩm CRM nào cho team 10 người không?
```

```text
Tôi muốn bảo hành sản phẩm thì quy trình thế nào?
```

```text
Gói Pro khác Basic ở điểm nào?
```

## Cách Nâng Cấp Sau

- Lưu lịch sử chat vào Google Sheets/Postgres để AI có memory.
- Tách file JSON lớn thành nhiều file theo nhóm sản phẩm.
- Thêm node Google Sheets để log câu hỏi và câu trả lời.
- Thêm nhánh handoff cho nhân viên khi AI không tìm thấy thông tin.
