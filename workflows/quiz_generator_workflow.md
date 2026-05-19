# 🎓 Hướng dẫn: Quiz Generator — Google Drive → AI → Google Form

> **File workflow:** `workflows/quiz_generator_workflow.json`  
> **AI Model:** Google Gemini — `gemini-2.5-pro-preview`

## Mục tiêu

Tự động tạo bộ câu hỏi quiz trắc nghiệm từ tài liệu Markdown:
1. User cung cấp đường dẫn **Google Drive folder**
2. Workflow đọc toàn bộ file `.md` trong folder
3. **AI (Gemini `gemini-2.5-pro-preview`)** phân tích nội dung và sinh câu hỏi
4. Push toàn bộ bộ câu hỏi lên **Google Form** ở chế độ Quiz

---

## Sơ đồ luồng

```
POST /webhook/generate-quiz
          │
          ▼
[Parse Input & Extract Folder ID]
          │
          ▼
[List Files in Google Drive Folder]
          │
          ▼
[Filter Markdown Files]  ← chỉ giữ .md / .markdown
          │
          │  (lặp qua từng file)
          ▼
[Download Markdown File Content]
          │
          ▼
[Extract Text Content]   ← decode binary → text
          │
          ▼
[AI Generate Quiz Questions]  ← Gemini 2.5 Pro Preview
          │
          ▼
[Parse AI Quiz Response]
          │
          ▼  (gộp từ tất cả files)
[Aggregate All Quiz Questions]
          │
          ▼
[Merge & Prepare Quiz Data]
          │
          ▼
[Create Google Form]   ← Forms API: tạo form mới
          │
          ▼
[Extract Form ID]
          │
          ▼
[Add Quiz Questions to Form]  ← batchUpdate
          │
          ▼
[Build Success Response]
          │
          ▼
[Respond to Webhook]  → { formUrl, editUrl, totalQuestions }
```

---

## Tất cả Nodes

| # | Tên Node | Type | Chức năng |
|---|----------|------|-----------|
| 1 | Webhook Trigger | `n8n-nodes-base.webhook` | Nhận POST request từ user |
| 2 | Parse Input & Extract Folder ID | `n8n-nodes-base.code` | Validate input, extract folder ID |
| 3 | List Files in Google Drive Folder | `n8n-nodes-base.googleDrive` | Liệt kê tất cả files trong folder |
| 4 | Filter Markdown Files | `n8n-nodes-base.code` | Chỉ giữ `.md` / `.markdown` |
| 5 | Download Markdown File Content | `n8n-nodes-base.googleDrive` | Tải nội dung file (binary) |
| 6 | Extract Text Content | `n8n-nodes-base.code` | Decode base64 → UTF-8 string |
| 7 | AI Generate Quiz Questions | `n8n-nodes-base.httpRequest` | Gọi Gemini API tạo câu hỏi |
| 8 | Parse AI Quiz Response | `n8n-nodes-base.code` | Parse & validate JSON từ AI |
| 9 | Aggregate All Quiz Questions | `n8n-nodes-base.aggregate` | Gộp kết quả tất cả files |
| 10 | Merge & Prepare Quiz Data | `n8n-nodes-base.code` | Tổng hợp metadata + câu hỏi |
| 11 | Create Google Form | `n8n-nodes-base.httpRequest` | Tạo Google Form mới (Forms API) |
| 12 | Extract Form ID | `n8n-nodes-base.code` | Lấy formId từ response |
| 13 | Add Quiz Questions to Form | `n8n-nodes-base.httpRequest` | batchUpdate: push câu hỏi |
| 14 | Build Success Response | `n8n-nodes-base.code` | Format response JSON |
| 15 | Respond to Webhook | `n8n-nodes-base.respondToWebhook` | Trả response về user |
| E1 | Error Handler | `n8n-nodes-base.code` | Xử lý lỗi toàn workflow |
| E2 | Respond Error to Webhook | `n8n-nodes-base.respondToWebhook` | Trả HTTP 500 + thông tin lỗi |

---

## ⚠️ Thiết lập OAuth2 cho Localhost

Khi chạy n8n trên `localhost`, Google OAuth2 **không tự động redirect về localhost** vì Google yêu cầu HTTPS với domain thật. Có 2 cách giải quyết:

---

### Cách 1: Desktop App (Khuyến nghị cho local dev)

Đây là cách **đơn giản nhất** — không cần domain, không cần HTTPS.

#### Bước 1: Tạo OAuth Client dạng Desktop

```
Google Cloud Console
  → APIs & Services
  → Credentials
  → + Create Credentials → OAuth client ID
  → Application type: Desktop app          ← chọn đây
  → Name: "n8n Local Dev"
  → Create
  → Copy Client ID và Client Secret
```

#### Bước 2: Cấu hình trong n8n

```
n8n → Settings → Credentials → Add Credential
  → Google Drive OAuth2 API
  → Client ID:     [paste]
  → Client Secret: [paste]
  → Click "Connect my account"
  → Đăng nhập Google và cấp quyền
```

> ✅ n8n sẽ xử lý redirect flow tự động với Desktop app — không cần đăng ký redirect URI.

---

### Cách 2: Web App + Override WEBHOOK_URL

Dùng khi đã có OAuth Client dạng **Web application** hoặc cần test production-like flow.

#### Bước 1: Cập nhật `.env` để override WEBHOOK_URL

Mở file `.env` và uncomment phần LOCAL DEVELOPMENT OVERRIDE:

```bash
# .env
WEBHOOK_URL=http://localhost:5678/
N8N_HOST=localhost
N8N_PROTOCOL=http
N8N_PORT_MAPPING=5678:5678
```

#### Bước 2: Restart n8n để áp dụng

```bash
docker compose down
docker compose up -d
```

#### Bước 3: Lấy callback URL từ n8n

```
n8n → Settings → Credentials → Add → Google Drive OAuth2 API
  → Nhập Client ID + Client Secret
  → Xem URL hiện thị trong ô "OAuth Redirect URL":
    http://localhost:5678/rest/oauth2-credential/callback
```

#### Bước 4: Đăng ký redirect URI trong Google Cloud

```
Google Cloud Console
  → APIs & Services → Credentials
  → Chọn OAuth Client đã tạo → Edit
  → Authorized redirect URIs → + Add URI:

    http://localhost:5678/rest/oauth2-credential/callback

  → Save
```

> ⚠️ URI phải **khớp chính xác từng ký tự** — bao gồm `http://`, port `:5678`, và path `/rest/oauth2-credential/callback`.

#### Bước 5: Setup OAuth Consent Screen (nếu chưa có)

```
Google Cloud Console
  → APIs & Services → OAuth consent screen
  → User Type: External → Create
  → App name: "n8n Local"
  → Support email: [your email]
  → Test users → + Add Users → [your Google email]
  → Save
```

---

### Cách 3: Dùng ngrok / Cloudflare Tunnel (Production-like)

Khi cần test với HTTPS thật và Web App flow:

```bash
# Cài ngrok
brew install ngrok

# Expose port 5678
ngrok http 5678
# → Lấy URL: https://abc123.ngrok-free.app
```

Cập nhật `.env`:
```bash
WEBHOOK_URL=https://abc123.ngrok-free.app/
N8N_HOST=abc123.ngrok-free.app
N8N_PROTOCOL=https
N8N_PORT_MAPPING=5678:5678
```

Sau đó đăng ký redirect URI trong Google Cloud:
```
https://abc123.ngrok-free.app/rest/oauth2-credential/callback
```

---

### So sánh các cách

| Cách | Độ phức tạp | HTTPS | Phù hợp |
|------|------------|-------|---------|
| Desktop App | ⭐ Dễ nhất | ❌ Không cần | Local dev, học tập |
| WEBHOOK_URL Override | ⭐⭐ | ❌ HTTP | Local dev + Web App client |
| ngrok / Tunnel | ⭐⭐⭐ | ✅ | Test production flow |

---

### Troubleshooting OAuth

| Lỗi | Nguyên nhân | Giải pháp |
|-----|------------|-----------|
| `redirect_uri_mismatch` | URI không khớp | Copy chính xác URI từ n8n UI, paste vào Cloud Console |
| `Access blocked: app not verified` | Consent screen chưa có test user | Thêm email vào Test Users trong OAuth consent screen |
| `Callback URL sai (vẫn là example.com)` | WEBHOOK_URL chưa được apply | Restart `docker compose down && up -d` |
| `400 Error` sau khi login Google | Client type sai (Web vs Desktop) | Tạo lại credential với đúng Application type |

---

## Credentials cần thiết

### 1. Google Drive OAuth2

```
Scopes cần bật:
  ✅ https://www.googleapis.com/auth/drive.readonly
```

**Cách cấu hình:**
```
1. Google Cloud Console → APIs & Services → Credentials
2. Tạo OAuth 2.0 Client ID (Desktop hoặc Web)
3. n8n → Settings → Credentials → Add → Google Drive OAuth2
4. Nhập Client ID + Client Secret → Connect Account
```

### 2. Google Forms OAuth2

```
APIs cần bật trước:
  ✅ Google Forms API (trong Google Cloud Console)

Scopes cần bật:
  ✅ https://www.googleapis.com/auth/forms.body
  ✅ https://www.googleapis.com/auth/forms.body.readonly
```

**Cách bật Google Forms API:**
```
Google Cloud Console
  → APIs & Services
  → Library
  → Search "Google Forms API"
  → Enable
```

### 3. Google Gemini API Key (HTTP Query Auth)

Workflow gọi Gemini thông qua HTTP Request với API Key truyền qua query parameter `key=`.

```
1. Truy cập https://aistudio.google.com/app/apikey
2. Click "Create API key"
3. Chọn project Google Cloud
4. Copy API key
```

**Tạo credential trong n8n:**
```
n8n → Settings → Credentials → Add Credential
  → Tìm "HTTP Query Auth"
  → Name: Google Gemini API Key
  → Name (param): key
  → Value: <paste API key>
  → Save
```

> ⚠️ Gemini API Key từ AI Studio có free tier giới hạn RPM. Nếu cần production, dùng Vertex AI với Service Account.

---

## Cài đặt & Import

### Bước 1: Import workflow vào n8n

```
n8n Dashboard
  → Add workflow
  → ⋮ (menu)
  → Import from File
  → Chọn: workflows/quiz_generator_workflow.json
```

### Bước 2: Gán credentials

Sau khi import, mở từng node và gán credential tương ứng:

| Node | Credential cần gán |
|------|--------------------|
| List Files in Google Drive Folder | Google Drive OAuth2 |
| Download Markdown File Content | Google Drive OAuth2 |
| AI Generate Quiz Questions | Google Gemini API Key (HTTP Query Auth) |
| Create Google Form | Google Forms OAuth2 |
| Add Quiz Questions to Form | Google Forms OAuth2 |

### Bước 3: Activate

```
Toggle "Inactive" → "Active" (góc trên phải)
```

---

## Sử dụng

### API Endpoint

```
POST http://localhost:5678/webhook/generate-quiz
Content-Type: application/json
```

### Request Body

```json
{
  "folderUrl": "https://drive.google.com/drive/folders/1ABC123xyz",
  "quizTitle": "Quiz N8N - Workflow Automation",
  "questionsPerFile": 3,
  "description": "Kiểm tra kiến thức về n8n automation"
}
```

| Field | Bắt buộc | Mặc định | Mô tả |
|-------|----------|----------|-------|
| `folderUrl` | ✅ | — | URL hoặc Folder ID từ Google Drive |
| `quizTitle` | ❌ | `"Quiz từ tài liệu Markdown"` | Tiêu đề Google Form |
| `questionsPerFile` | ❌ | `3` | Số câu hỏi sinh ra từ mỗi file `.md` |
| `description` | ❌ | Auto | Mô tả form |

### Lấy Google Drive Folder URL

```
Mở folder trên Google Drive
  → Click chuột phải → "Get link"
  → Copy URL dạng:
    https://drive.google.com/drive/folders/1ABC123xyz
                                           ↑
                               Workflow tự extract ID này
```

### Test bằng curl

```bash
curl -X POST http://localhost:5678/webhook/generate-quiz \
  -H "Content-Type: application/json" \
  -d '{
    "folderUrl": "https://drive.google.com/drive/folders/YOUR_FOLDER_ID",
    "quizTitle": "Quiz Kiến Thức N8N",
    "questionsPerFile": 3
  }'
```

---

## Response

### Thành công (HTTP 200)

```json
{
  "success": true,
  "message": "✅ Đã tạo thành công bộ quiz với 15 câu hỏi từ 5 file Markdown",
  "result": {
    "formId": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms",
    "formTitle": "Quiz Kiến Thức N8N",
    "formUrl": "https://docs.google.com/forms/d/e/.../viewform",
    "editUrl": "https://docs.google.com/forms/d/1BxiMV.../edit",
    "totalQuestions": 15,
    "totalFilesProcessed": 5
  }
}
```

### Lỗi (HTTP 500)

```json
{
  "success": false,
  "message": "❌ Có lỗi xảy ra trong quá trình tạo quiz",
  "error": {
    "message": "Không tìm thấy file Markdown (.md) nào trong folder",
    "node": "Filter Markdown Files"
  },
  "troubleshooting": [
    "Kiểm tra Google Drive credentials đã được cấp quyền chưa",
    "Kiểm tra folder URL có đúng định dạng không",
    "Kiểm tra folder có chứa file .md không",
    "Kiểm tra Google Gemini API key còn quota không",
    "Kiểm tra Google Forms API đã được bật chưa",
    "Kiểm tra Gemini model name: gemini-2.5-pro-preview"
  ]
}
```

---

## Cấu trúc câu hỏi AI sinh ra

Gemini được yêu cầu trả về JSON theo format (dùng `responseMimeType: application/json`):

```json
{
  "questions": [
    {
      "question": "Node nào trong n8n dùng để chạy code JavaScript tùy ý?",
      "options": {
        "A": "HTTP Request Node",
        "B": "Code Node",
        "C": "Function Node",
        "D": "Script Node"
      },
      "correctAnswer": "B",
      "explanation": "Code Node cho phép viết JavaScript hoặc Python để xử lý dữ liệu trong workflow"
    }
  ]
}
```

**Gemini API Response structure** (trước khi parse):
```json
{
  "candidates": [{
    "content": {
      "parts": [{ "text": "{\"questions\": [...]}" }]
    },
    "finishReason": "STOP"
  }]
}
```

> Câu hỏi được push lên Google Form ở chế độ **Quiz** với 1 điểm mỗi câu, tự chấm điểm và hiện giải thích sau khi nộp.

---

## Giới hạn kỹ thuật

| Giới hạn | Giá trị | Lý do |
|----------|---------|-------|
| Nội dung mỗi file | 8,000 ký tự | Tránh vượt context window limit |
| Định dạng hỗ trợ | `.md`, `.markdown` | Chỉ xử lý Markdown thuần |
| AI model | `gemini-2.5-pro-preview` | Reasoning mạnh, native JSON output |
| Max output tokens | 2,000 | Đủ cho ~5 câu hỏi chi tiết |
| Đáp án mỗi câu | 4 lựa chọn (A-D) | Theo chuẩn trắc nghiệm |

---

## Troubleshooting

| Triệu chứng | Nguyên nhân | Giải pháp |
|-------------|-------------|-----------|
| `Không tìm thấy file .md` | Folder không có file Markdown | Upload file `.md` vào Drive folder |
| `403 Forbidden` trên Drive | Thiếu quyền đọc folder | Share folder với tài khoản Google đã connect |
| `Google Forms API error` | API chưa được bật | Enable Google Forms API trong Cloud Console |
| `429 RESOURCE_EXHAUSTED` | Gemini free tier bị rate limit | Chờ 1 phút hoặc nâng lên paid tier |
| `400 INVALID_ARGUMENT` | Model name sai | Kiểm tra model: `gemini-2.5-pro-preview` |
| `finishReason: SAFETY` | Nội dung bị safety filter block | Kiểm tra nội dung file .md |
| Gemini không trả JSON | `responseMimeType` fallback | Code node regex parse sẽ xử lý tự động |
| `Invalid credentials` | API key sai hoặc hết hạn | Kiểm tra HTTP Query Auth credential |
| Form tạo ra nhưng không có câu hỏi | batchUpdate thất bại | Kiểm tra scope `forms.body` đã được cấp |

---

## Mở rộng

### Đổi sang model Gemini khác

Chỉnh URL trong node `AI Generate Quiz Questions`:
```
# Nhanh hơn, rẻ hơn (free tier):
https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent

# Mạnh hơn:
https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro-preview:generateContent
```

### Dùng Vertex AI thay AI Studio (production)

Thay HTTP Request bằng Service Account + Vertex AI endpoint:
```
POST https://REGION-aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/REGION/publishers/google/models/gemini-2.5-pro-preview:generateContent
Authorization: Bearer {service_account_token}
```

### Gửi link Form qua Email sau khi tạo

Thêm node Gmail sau `Build Success Response`:
```json
{
  "sendTo": "={{ $('Webhook Trigger').first().json.body.email }}",
  "subject": "✅ Quiz đã được tạo thành công",
  "message": "Xem form tại: {{ $json.result.formUrl }}"
}
```

### Thêm time limit cho Quiz

Trong node `Add Quiz Questions to Form`, bổ sung vào `updateSettings`:
```json
{
  "quizSettings": {
    "isQuiz": true
  }
}
```

> Google Forms API hiện chưa hỗ trợ time limit qua API. Cần set thủ công trong giao diện Form Editor.
