# 📋 Hướng dẫn: Quiz Generator V3

> **File workflow:** `workflows/quiz_generator_workflow_v3.json`

## Mục tiêu

Tạo quiz tự động từ tài liệu Markdown trong Google Drive:
- Đọc files Markdown từ Google Drive folder
- AI (OpenAI) generates câu hỏi
- Output: Google Forms hoặc JSON

---

## Sơ đồ luồng

```
[Webhook (POST /generate-quiz)]
         │
         ▼
[Parse Input & Extract Folder ID]
         │
         ▼
[List Files in Google Drive Folder]
         │
         ▼
[Filter Markdown Files]
         │
         ▼
[For Each File:]
    │
    ├── Download File Content
    │        │
    │        ▼
    │   Generate Questions (OpenAI)
    │        │
    │        ▼
    │   Format Output
    │
    ▼
[Create Google Form (or Return JSON)]
         │
         ▼
[Return Response]
```

---

## Webhook Input

```json
{
  "folderUrl": "https://drive.google.com/drive/folders/FOLDER_ID",
  "quizTitle": "Tên Quiz",
  "questionsPerFile": 3,
  "description": "Mô tả quiz (optional)"
}
```

---

## Credentials cần thiết

| Credential | Cách tạo |
|-----------|----------|
| **Google Drive OAuth2** | Settings → Credentials → Add → Google Drive → Connect |
| **OpenAI API** | Settings → Credentials → Add → OpenAI → Paste API Key |
| **Google Forms OAuth2** (optional) | Settings → Credentials → Add → Google Forms → Connect |

---

## Test

```bash
curl -X POST http://localhost:5678/webhook/generate-quiz \
  -H "Content-Type: application/json" \
  -d '{
    "folderUrl": "https://drive.google.com/drive/folders/YOUR_FOLDER_ID",
    "quizTitle": "Quiz Kiến thức Cơ bản",
    "questionsPerFile": 3
  }'
```

---

## ⚠️ Lưu ý Community Version

1. **OpenAI API Cost**: Mỗi request tốn ~$0.01-0.05 tùy số lượng câu hỏi
2. **Google Drive API**: Có quota limits — đủ dùng cho personal/small team
3. **Wait for AI**: AI generation có thể mất 10-30 seconds. Webhook timeout default là 60s — đủ dùng

---

## Credits

- **Phiên bản:** V3
- **Cập nhật:** 2026-05-05
