# Hướng Dẫn: Company RAG Chatbot — AI Agent + DeepSeek + Pinecone trên n8n Community

Workflow này xây dựng **chatbot hỏi đáp nội bộ công ty** sử dụng kỹ thuật **RAG (Retrieval-Augmented Generation)**: chatbot tra cứu thông tin chính xác từ tài liệu thực của doanh nghiệp (quy trình, sản phẩm, chính sách) thay vì trả lời chung chung hoặc bịa đặt.

- **AI Agent**: `DeepSeek` (`deepseek-chat`) — mô hình ngôn ngữ xử lý câu hỏi
- **Vector Database**: `Pinecone` — lưu trữ bền vững, không mất dữ liệu khi restart n8n
- **Embedding**: `Google Gemini` (`gemini-embedding-001`) — chuyển văn bản thành vector để tìm kiếm ngữ nghĩa (768 dims)
- **Giao diện**: Chat UI tích hợp sẵn của n8n (không cần frontend)

> Toàn bộ chỉ dùng **node có sẵn của n8n Community** — không cần Enterprise, không cài thêm package.

---

## 1. Kiến trúc tổng thể

```
╔══════════════════════════════════════════════════════════════════════╗
║  WORKFLOW 1 — NẠP DỮ LIỆU (chạy tay 1 lần / khi cập nhật)          ║
║                                                                      ║
║  Form Upload (browser, không cần terminal)                           ║
║    → Parse JSON từ file binary                                       ║
║    → Code: Tạo Documents (sản phẩm / quy trình / chính sách / FAQ)  ║
║    → Pinecone Vector Store [INSERT, index=company-kb, ns=company]    ║
║         ↑ Default Data Loader ← Recursive Text Splitter (800 chars) ║
║         ↑ Gemini Embeddings (text-embedding-004, 768 dims)           ║
╚══════════════════════════════════════════════════════════════════════╝

╔══════════════════════════════════════════════════════════════════════╗
║  WORKFLOW 2 — CHATBOT (activate để chạy nền liên tục)               ║
║                                                                      ║
║  Chat Trigger (n8n Chat UI)                                          ║
║    → AI Agent                                                        ║
║         ↑ DeepSeek Chat Model (deepseek-chat) ─── ai_languageModel  ║
║         ↑ Window Buffer Memory (10 turns) ──────── ai_memory        ║
║         ↑ Pinecone RAG Tool [RETRIEVE-AS-TOOL] ─── ai_tool          ║
║              (index=company-kb, ns=company, topK=5)                  ║
║              ↑ Gemini Embeddings (text-embedding-004)                ║
╚══════════════════════════════════════════════════════════════════════╝
```

**Vì sao cần 2 workflow?** Workflow 1 chạy một lần để "nạp" tri thức vào Pinecone. Workflow 2 chạy mãi để phục vụ người dùng — mỗi khi có câu hỏi, AI Agent tự gọi tool RAG, tìm đoạn văn liên quan nhất trong Pinecone, rồi dùng DeepSeek tổng hợp câu trả lời chính xác theo dữ liệu thực.

**Ưu điểm của Pinecone so với In-Memory Store:**

| Tiêu chí | Simple Vector Store (In-Memory) | Pinecone |
|---|---|---|
| Lưu bền vững | ❌ Mất khi restart | ✅ Lưu vĩnh viễn |
| Dung lượng | ❌ Giới hạn RAM | ✅ Lên đến triệu vectors |
| Chi phí | ✅ Miễn phí | ✅ Free tier 100K vectors |
| Setup | ✅ Không cần cấu hình | ⚠️ Cần tạo account + index |

---

## 2. Các file trong thư mục

| File | Vai trò |
|------|---------|
| `company_knowledge.json` | Dữ liệu tri thức mẫu của công ty (thay bằng dữ liệu thật của bạn) |
| `01-ingest.json` | Workflow nạp dữ liệu vào Pinecone (chạy tay) |
| `02-chatbot.json` | Workflow chatbot AI Agent + RAG Pinecone + DeepSeek — giao diện **Chat UI** tích hợp sẵn của n8n |
| `03-telegram-chatbot.json` | **Phiên bản Telegram (DeepSeek)** — cùng RAG Pinecone, trả lời qua bot Telegram (xem [mục 14](#14-phiên-bản-telegram-bot)) |
| `04-telegram-chatbot-gemini.json` | **Phiên bản Telegram (Gemini)** — giống `03` nhưng dùng Google Gemini làm model. **Khuyến nghị dùng bản này** vì Gemini gọi tool ổn định với AI Agent (DeepSeek hiện lỗi `reasoning_content` khi tool calling — xem [mục 14.8](#148-vì-sao-có-2-phiên-bản-telegram-deepseek-vs-gemini)) |
| `GUIDE.md` | Tài liệu này |

> **Hai phiên bản chatbot dùng chung một kho dữ liệu Pinecone.** Cả `02-chatbot.json` (Chat UI) và `03-telegram-chatbot.json` (Telegram) đều truy vấn cùng index `company-kb` / namespace `company` đã nạp bằng `01-ingest.json`. Bạn chỉ cần nạp dữ liệu **một lần**, rồi chọn dùng giao diện nào tùy nhu cầu (hoặc dùng cả hai).

---

## 3. Yêu cầu chuẩn bị

1. **n8n** đang chạy (Docker Compose trong repo, image `docker.n8n.io/n8nio/n8n:latest`).
2. **DeepSeek API Key** — đăng ký tại [platform.deepseek.com](https://platform.deepseek.com). Nạp credit tối thiểu (~5 USD là đủ để test nhiều).
3. **Google Gemini API Key** — lấy miễn phí tại [Google AI Studio](https://aistudio.google.com/app/apikey). Dùng cho embedding.
4. **Pinecone Account** — đăng ký miễn phí tại [pinecone.io](https://www.pinecone.io). Free tier: 2 indexes, 100K vectors — đủ dùng cho demo.

---

## 4. Bước 1 — Tạo Pinecone Index

> Đây là bước quan trọng nhất. Index phải có đúng số chiều (dimensions) tương ứng với model embedding.

1. Đăng nhập [Pinecone Console](https://app.pinecone.io).
2. Nhấn **"Create index"**.
3. Chọn **"Dense"** (không chọn "Integrated Embedding" — loại đó dùng model nội bộ của Pinecone, không tương thích với n8n).

4. Điền thông tin:

   | Trường | Giá trị |
   |--------|---------|
   | **Index name** | `company-kb` |
   | **Dimensions** | `768` |
   | **Metric** | `cosine` |
   | **Cloud / Region** | `AWS / us-east-1` |

5. Nhấn **"Create index"** và đợi status chuyển sang **"Ready"** (khoảng 1-2 phút).

> **Tại sao dimensions = 768?** Model `gemini-embedding-001` sinh vector 768 chiều. Không dùng `gemini-embedding-2` (3072 dims — tốn storage hơn, không cần thiết cho text thuần túy). Quan trọng: chọn index loại **Dense** (không phải "Integrated Embedding").

---

## 5. Bước 2 — Tạo Credentials trên n8n

### 5.1 DeepSeek Credential

1. Vào n8n → **Credentials** → **New** → tìm **"DeepSeek"**.
2. Dán **API Key** từ DeepSeek Platform.
3. Lưu với tên: `DeepSeek account`.

### 5.2 Google Gemini Credential (cho Embedding)

1. Vào n8n → **Credentials** → **New** → tìm **"Google Gemini(PaLM) Api"**.
2. Dán **API Key** từ Google AI Studio.
3. Để nguyên Host mặc định.
4. Lưu với tên: `Google Gemini(PaLM) Api account`.

### 5.3 Pinecone Credential

1. Vào n8n → **Credentials** → **New** → tìm **"Pinecone"**.
2. Vào Pinecone Console → **API Keys** → copy key mặc định.
3. Dán vào ô **API Key** trên n8n.
4. Lưu với tên: `Pinecone account`.

---

## 6. Bước 3 — Import và Cấu hình Workflow

### 6.1 Import 2 workflows

1. Vào n8n → **Workflows** → **Import from file**.
2. Import `01-ingest.json` trước, rồi `02-chatbot.json`.

### 6.2 Gán credentials cho Workflow 01 (01-ingest.json)

Sau khi import, mở workflow 01, gán credentials cho từng node:

| Node | Credential cần gán |
|------|---------------------|
| `🗄️ Pinecone: Nạp Documents (Insert)` | `Pinecone account` |
| `🔢 Gemini Embeddings` | `Google Gemini(PaLM) Api account` |

### 6.3 Gán credentials cho Workflow 02 (02-chatbot.json)

| Node | Credential cần gán |
|------|---------------------|
| `🧠 DeepSeek Chat Model` | `DeepSeek account` |
| `🔎 RAG: Company Knowledge Base` | `Pinecone account` |
| `🔢 Gemini Embeddings` | `Google Gemini(PaLM) Api account` |

---

## 7. Bước 4 — Chuẩn bị và Nạp Dữ liệu vào Pinecone

### 7.1 Tùy chỉnh company_knowledge.json (tùy chọn)

File `company_knowledge.json` có cấu trúc:

```json
{
  "company": { "name": "...", "hotline": "...", ... },
  "products": [ { "id": "SW001", "name": "...", "price": ..., ... } ],
  "processes": [ { "id": "HR001", "name": "...", "steps": [...], ... } ],
  "policies": { "work_from_home": "...", "overtime": "...", ... },
  "faq": [ { "q": "...", "a": "..." } ]
}
```

Bạn có thể:
- **Dùng luôn dữ liệu mẫu** để test trước, không cần chỉnh.
- **Thay bằng dữ liệu thật** của công ty bạn sau khi test xong.

### 7.2 Upload file qua Form (không cần terminal)

Workflow 01 dùng **n8n Form Trigger** — bạn upload file trực tiếp từ trình duyệt, không cần `docker cp` hay lệnh nào khác.

Có **2 cách** mở form, tùy bạn muốn test nhanh hay dùng production:

---

#### Cách A — Test nhanh (không cần Activate workflow)

Phù hợp khi chỉ cần nạp dữ liệu 1 lần và không muốn để workflow chạy nền.

**Bước 1:** Mở workflow **01 — RAG Ingest**, nhấn nút **"Execute workflow"** (▶️ góc trên phải).

> Workflow vào trạng thái "chờ kích hoạt" — thanh trạng thái hiển thị *"Waiting for trigger event"*.

**Bước 2:** Double-click vào node `📁 Form Upload company_knowledge.json` → panel bên phải hiện ra → thấy nút **"Open form"** hoặc dòng **Test URL**.

```
Test URL:  http://localhost:5678/form-test/wf17-form-ingest-001
```

Nhấn nút **"Open form"** (hoặc copy URL → dán vào tab trình duyệt mới).

**Bước 3:** Trang form hiện ra trong trình duyệt:

```
┌─────────────────────────────────────────────┐
│   Nạp Dữ Liệu Công Ty vào Pinecone          │
│                                              │
│   Upload file company_knowledge.json để     │
│   nạp tri thức công ty vào Pinecone.         │
│                                              │
│   data *                                     │
│   [ Choose File ]  No file chosen            │
│                                              │
│              [ Submit ]                      │
└─────────────────────────────────────────────┘
```

**Bước 4:** Nhấn **"Choose File"** → chọn file `company_knowledge.json` từ máy tính của bạn.

**Bước 5:** Nhấn **"Submit"** → trang báo *"✅ File đã được nhận! Quá trình nạp dữ liệu đang chạy..."*

**Bước 6:** Quay lại n8n → workflow tự động chạy hết các node → thanh trạng thái chuyển xanh ✅.

---

#### Cách B — Production URL (Activate workflow)

Phù hợp khi muốn form luôn sẵn sàng để upload lại nhiều lần mà không cần nhấn Execute.

**Bước 1:** Nhấn toggle **Inactive** → **Active** (góc trên phải workflow).

**Bước 2:** Double-click vào node `📁 Form Upload company_knowledge.json` → panel bên phải hiện **Production URL**:

```
Production URL:  http://localhost:5678/form/wf17-form-ingest-001
```

Nhấn icon **copy** bên cạnh URL.

**Bước 3:** Dán URL vào trình duyệt → form hiện ra → upload file → Submit (giống Cách A từ Bước 3 trở đi).

---

> **Lưu ý quan trọng:**
> - **Test URL** chỉ hoạt động khi workflow đang ở chế độ "Execute" trong editor (thanh xanh "Waiting for trigger").
> - **Production URL** chỉ hoạt động khi workflow đã được **Activate**.
> - Sau khi nạp dữ liệu xong, bạn có thể **Deactivate** workflow 01 (không cần để chạy nền như workflow chatbot).

### 7.3 Kiểm tra kết quả nạp dữ liệu

Sau khi Submit form và workflow chạy xong:

1. Vào n8n → **Executions** → chọn execution vừa chạy.
2. Kiểm tra từng node:
   - Node `🧩 Tạo Documents` → phải có **> 20 items** (cho dữ liệu mẫu TechViet).
   - Node `🗄️ Pinecone: Nạp Documents` → Status **"Success"**.
3. Vào **Pinecone Console** → chọn index `company-kb` → xem **"Total vectors"** (phải > 20).

> Workflow 01 chỉ cần chạy **1 lần**. Chạy lại khi bạn cập nhật `company_knowledge.json`. Pinecone sẽ **thêm** vectors mới (không tự xóa cũ) — nếu muốn làm mới hoàn toàn, vào Pinecone Console xóa namespace `company` rồi chạy lại.

---

## 8. Bước 5 — Kích hoạt và Test Chatbot

### 8.1 Activate Workflow 02

1. Mở workflow **02 — Company RAG Chatbot**.
2. Nhấn nút **Inactive** (góc trên phải) để chuyển sang **Active**.
3. Copy **Production URL** của Chat Trigger (hiện ra sau khi activate).

### 8.2 Mở giao diện Chat

- Dán URL vào trình duyệt → giao diện chat của n8n hiện ra.
- Hoặc test trực tiếp trong n8n bằng cách nhấn **"Chat"** ở thanh trên.

### 8.3 Test câu hỏi mẫu

Thử các câu hỏi sau để kiểm tra:

```
Công ty có những sản phẩm/dịch vụ gì?
TechViet ERP giá bao nhiêu và có tính năng gì?
Quy trình nghỉ phép như thế nào?
Chính sách WFH của công ty ra sao?
Muốn mua phần mềm CRM thì liên hệ ai?
Lương được thanh toán vào ngày nào?
```

**Kết quả mong đợi:**
- Chatbot trích dẫn thông tin chính xác từ `company_knowledge.json`.
- Không bịa đặt số liệu hay quy trình không có trong tài liệu.
- Khi hỏi ngoài phạm vi: "Tôi không tìm thấy thông tin này trong tài liệu nội bộ."

---

## 9. Luồng hoạt động chi tiết

```
Người dùng gõ câu hỏi
        ↓
Chat Trigger nhận câu hỏi + sessionId
        ↓
AI Agent (DeepSeek-chat) nhận câu hỏi
        ↓
Agent quyết định gọi tool "company_knowledge"
        ↓
Gemini Embeddings chuyển câu hỏi → vector 768 chiều
        ↓
Pinecone tìm kiếm top-5 đoạn văn gần nhất trong index "company-kb"
        ↓
Pinecone trả về 5 đoạn context phù hợp nhất
        ↓
DeepSeek tổng hợp câu trả lời từ context + câu hỏi
        ↓
Window Buffer Memory lưu lượt hội thoại này (10 lượt gần nhất)
        ↓
Trả về câu trả lời cho người dùng
```

---

## 10. Tùy chỉnh nâng cao

### 10.1 Đổi model DeepSeek

Mở node `🧠 DeepSeek Chat Model` → thay **Model**:

| Model | Đặc điểm |
|-------|----------|
| `deepseek-chat` | DeepSeek-V3. Mặc định. Cân bằng tốt về chất lượng và chi phí |
| `deepseek-reasoner` | DeepSeek-R1. Suy luận mạnh hơn, nhưng chậm hơn và đắt hơn |

Lưu ý: n8n sẽ tự động load danh sách model từ DeepSeek API khi bạn mở dropdown.

### 10.2 Tăng số kết quả tìm kiếm

Mở node `🔎 RAG: Company Knowledge Base` → tăng **topK** (mặc định 5):
- `topK=3`: Nhanh hơn, ít context hơn
- `topK=8`: Nhiều context hơn nhưng tốn token hơn

### 10.3 Thêm nhiều loại dữ liệu

Mở file `company_knowledge.json`, thêm section mới (VD: `"promotions"`, `"announcements"`). Sau đó mở node `🧩 Tạo Documents Từ Knowledge JSON` trong workflow 01 và thêm code xử lý section mới vào cuối. Chạy lại workflow 01 để cập nhật Pinecone.

### 10.4 Tích hợp vào Telegram hoặc Slack

- **Telegram**: dùng file `03-telegram-chatbot.json` có sẵn trong thư mục này → xem hướng dẫn chi tiết ở [mục 14](#14-phiên-bản-telegram-bot).
- **Slack (app_mention)**: tham khảo workflow `16-slack-product-rag-agent` trong repo này.

---

## 11. Xử lý sự cố

| Triệu chứng | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| Mở form URL bị lỗi 404 | Test URL mà workflow chưa ở chế độ Execute | Nhấn **"Execute workflow"** trước, sau đó mới mở form URL. Hoặc Activate workflow rồi dùng Production URL |
| Mở form URL bị lỗi 404 (Production URL) | Workflow chưa Active | Nhấn toggle Inactive → **Active** rồi thử lại |
| Form hiện ra nhưng Submit không có gì xảy ra | Workflow đã kết thúc chế độ test | Nhấn "Execute workflow" lại rồi Submit lại |
| Chatbot trả lời "không tìm thấy" dù có data | Chưa chạy workflow 01, hoặc sai namespace | Kiểm tra Pinecone console → Total vectors > 0. Kiểm tra namespace trong cả 2 workflow phải giống nhau (`company`) |
| Lỗi "dimension mismatch" khi ingest | Tạo index sai số chiều | Xóa index → tạo lại với dimensions=768 |
| Lỗi "Index not found" | Tên index trong n8n khác với Pinecone | Kiểm tra `pineconeIndex value` trong cả 2 workflow phải là `company-kb` |
| Embedding node lỗi 401/403 | Gemini credential sai | Kiểm tra API key tại Google AI Studio |
| DeepSeek node lỗi 401 | DeepSeek credential sai hoặc hết credit | Kiểm tra API key + credit tại DeepSeek Platform |
| Chatbot không nhớ câu hỏi trước | Mở tab mới (sessionId mới) | Normal — mỗi tab là session riêng. Tiếp tục trò chuyện trong cùng tab |
| Ingest chậm (>30s) | Pinecone free tier có rate limit | Giảm `embeddingBatchSize` xuống 50 trong node Pinecone Insert |
| Chat Trigger không hoạt động sau khi import | Workflow chưa được Activate | Nhấn toggle Inactive → Active |

---

## 12. Chi phí ước tính

| Dịch vụ | Free tier | Chi phí nếu dùng nhiều |
|---------|-----------|------------------------|
| **Pinecone** | 2 indexes, ~100K vectors, ~5 req/s | $0.08/GB/month sau free |
| **DeepSeek Chat** | - | ~$0.27/M input tokens (rất rẻ) |
| **Gemini Embedding** (`gemini-embedding-001`) | 1,500 req/ngày miễn phí | $0.000025/1K chars |

Với demo và thử nghiệm, tổng chi phí thường **dưới $1/tháng**.

---

## 13. Cấu trúc company_knowledge.json

Để mở rộng knowledge base, chỉ cần thêm entries vào JSON theo cấu trúc sau:

```json
{
  "company": { ... },           // Thông tin công ty
  "products": [                 // Sản phẩm/dịch vụ
    {
      "id": "SW001",
      "name": "Tên sản phẩm",
      "category": "Danh mục",
      "price": 10000000,        // VND (0 = liên hệ báo giá)
      "description": "Mô tả",
      "features": ["Tính năng 1", "Tính năng 2"],
      "in_stock": true,
      "tags": ["từ khóa tìm kiếm"]
    }
  ],
  "processes": [                // Quy trình nội bộ
    {
      "id": "HR001",
      "name": "Tên quy trình",
      "department": "Phòng ban",
      "steps": ["Bước 1", "Bước 2"],
      "contact": "email@congty.vn"
    }
  ],
  "policies": {                 // Chính sách (key tự đặt)
    "ten_chinh_sach": "Nội dung chính sách..."
  },
  "faq": [                      // Câu hỏi thường gặp
    { "q": "Câu hỏi?", "a": "Câu trả lời." }
  ]
}
```

---

## 14. Phiên bản Telegram Bot

File `03-telegram-chatbot.json` là **phiên bản chatbot trả lời qua Telegram**, dùng **chung kho dữ liệu Pinecone** đã nạp bằng `01-ingest.json` (không cần nạp lại). Thay vì Chat UI của n8n, người dùng nhắn tin trực tiếp cho bot Telegram và nhận câu trả lời RAG ngay trong Telegram.

### 14.1 Kiến trúc workflow Telegram

```
╔══════════════════════════════════════════════════════════════════════╗
║  WORKFLOW 3 — CHATBOT TELEGRAM (activate để chạy nền liên tục)      ║
║                                                                      ║
║  Telegram Trigger (nhận message)                                     ║
║    → Code: Tách Message & Chat ID (ép chat_id về String)            ║
║    → IF: Có Text?                                                   ║
║        ├─ TRUE → AI Agent                                           ║
║        │         ↑ DeepSeek Chat Model ───────── ai_languageModel  ║
║        │         ↑ Window Buffer Memory ───────── ai_memory        ║
║        │            (sessionKey = chat_id, customKey)               ║
║        │         ↑ Pinecone RAG Tool [RETRIEVE-AS-TOOL] ─ ai_tool   ║
║        │            ↑ Gemini Embeddings (gemini-embedding-001)       ║
║        │      → Code: Format câu trả lời (cắt 3900 ký tự)           ║
║        │      → Telegram: Gửi Trả Lời                               ║
║        └─ FALSE → Telegram: Nhắc người dùng gửi bằng chữ            ║
╚══════════════════════════════════════════════════════════════════════╝
```

> Embedding **bắt buộc** dùng đúng model `models/gemini-embedding-001` như `01-ingest.json` — sai model thì vector câu hỏi không khớp không gian vector đã nạp, RAG trả về rỗng mà **không báo lỗi**.

### 14.2 Tạo Telegram Bot và Credential

1. Mở Telegram, chat với **@BotFather** → gõ `/newbot` → đặt tên + username cho bot → BotFather trả về **bot token** (dạng `123456789:ABC...`).
2. Vào n8n → **Credentials** → **New** → tìm **"Telegram API"** → dán token → Lưu với tên `Telegram Bot`.

### 14.3 ⚠️ Bắt buộc: WEBHOOK_URL công khai (HTTPS)

Telegram **đẩy** tin nhắn tới n8n qua webhook, nên n8n phải có **URL công khai** mà server Telegram gọi tới được. Mặc định repo này chạy n8n ở `127.0.0.1:5678` (chỉ truy cập được trên máy bạn) → Telegram **không gửi tin tới được**.

Cách xử lý cho môi trường local (chọn 1 trong 2):

**Cách 1 — ngrok (nhanh nhất để test):**

```bash
ngrok http 5678
# ngrok trả về 1 URL HTTPS, ví dụ: https://abcd-1234.ngrok-free.app
```

Sửa file `.env` của repo:

```env
N8N_HOST=abcd-1234.ngrok-free.app
N8N_PROTOCOL=https
WEBHOOK_URL=https://abcd-1234.ngrok-free.app/
```

**Cách 2 — Cloudflare Tunnel** (ổn định hơn cho demo dài): tạo tunnel trỏ về `localhost:5678`, rồi điền domain HTTPS của tunnel vào `WEBHOOK_URL` tương tự.

Sau khi sửa `.env`, **khởi động lại** n8n để nhận biến mới:

```bash
docker compose up -d
```

> n8n chỉ đăng ký webhook với Telegram **khi workflow được Activate** và dùng giá trị `WEBHOOK_URL` lúc đó. Vì vậy phải set `WEBHOOK_URL` công khai **trước**, restart, **rồi mới Activate** workflow.
>
> Nếu bạn đã deploy n8n trên domain HTTPS thật (production) thì `WEBHOOK_URL` đã đúng sẵn, bỏ qua bước ngrok/tunnel.

### 14.4 Import và gán credentials cho Workflow 03

1. n8n → **Workflows** → **Import from File** → chọn `03-telegram-chatbot.json`.
2. Gán credentials:

| Node | Credential cần gán |
|------|---------------------|
| `📩 Telegram Trigger: Nhận Tin Nhắn` | `Telegram Bot` |
| `📤 Telegram: Gửi Trả Lời` | `Telegram Bot` |
| `📤 Telegram: Nhắc Gửi Text` | `Telegram Bot` |
| `🧠 DeepSeek Chat Model` | `DeepSeek account` |
| `🔎 RAG: Company Knowledge Base` | `Pinecone account` |
| `🔢 Gemini Embeddings` | `Google Gemini(PaLM) Api account` |

> Credentials DeepSeek / Pinecone / Gemini **dùng lại** từ phần [Bước 2 (mục 5)](#5-bước-2--tạo-credentials-trên-n8n) — không cần tạo mới.

### 14.5 Kích hoạt và Test

1. Đảm bảo đã chạy `01-ingest.json` (Pinecone có dữ liệu — xem [mục 7.3](#73-kiểm-tra-kết-quả-nạp-dữ-liệu)).
2. Bật toggle **Inactive → Active** cho workflow 03.
3. Mở Telegram → tìm bot của bạn theo username → nhấn **Start** → nhắn câu hỏi, ví dụ:

```
Công ty có những sản phẩm/dịch vụ gì?
Quy trình nghỉ phép như thế nào?
Chính sách WFH của công ty ra sao?
```

4. Bot trả lời dựa trên dữ liệu công ty trong Pinecone. Mỗi đoạn chat (chat_id) có bộ nhớ hội thoại riêng (10 lượt gần nhất).

### 14.6 Xử lý sự cố riêng cho Telegram

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Nhắn bot nhưng workflow không chạy | `WEBHOOK_URL` chưa public, hoặc chưa Activate | Set `WEBHOOK_URL` HTTPS công khai → `docker compose up -d` → Activate lại workflow |
| Lỗi `No session ID found` ở Window Buffer Memory | Memory để mặc định `fromInput` (chờ field `sessionId` của Chat Trigger) | Node memory phải đặt **Session ID = "Define below"** và Key = `chat_id` (file đã set sẵn `sessionIdType=customKey`) |
| Lỗi `reasoning_content in the thinking mode must be passed back` ở node DeepSeek | Bug n8n: AI Agent không gửi lại `reasoning_content` khi DeepSeek thinking mode gọi tool nhiều lượt | Dùng file **`04-telegram-chatbot-gemini.json`** (model Gemini) — xem [mục 14.8](#148-vì-sao-có-2-phiên-bản-telegram-deepseek-vs-gemini) |
| Bot không nhận khi gửi ảnh/sticker | Tin không có text | Bình thường — nhánh FALSE sẽ nhắc người dùng gửi bằng chữ |
| Bot trả lời "không tìm thấy" dù có data | Chưa chạy 01-ingest, sai namespace, hoặc sai model embedding | Pinecone phải có vectors > 0; namespace = `company`; embedding = `models/gemini-embedding-001` (khớp ingest) |
| Lỗi `can't parse entities: Can't find end of the entity...` khi gửi | Node Telegram **tự ép `parse_mode=Markdown`** nếu không set → câu trả lời AI có `*`/`_`/`[` không cân làm vỡ parser | File đã set `parse_mode=HTML` + escape `& < >` ở node Format + `appendAttribution=false`. Giữ nguyên cấu hình này; nếu tự sửa, đừng để trống parse_mode |
| Câu trả lời bị cắt cụt | Vượt giới hạn ~4096 ký tự của Telegram | Node Format đã cắt 3900 ký tự; có thể giảm `maxTokens` của DeepSeek nếu cần ngắn hơn |

### 14.7 So sánh các phiên bản chatbot

| Tiêu chí | `02-chatbot.json` (Chat UI) | `03` / `04` (Telegram) |
|---|---|---|
| Giao diện | Chat UI tích hợp sẵn n8n | App Telegram (điện thoại + máy tính) |
| Cần URL public | ❌ Không | ✅ Có (Telegram đẩy webhook) |
| Phân tách hội thoại | Theo session trình duyệt (mỗi tab) | Theo `chat_id` Telegram (mỗi người/nhóm) |
| Phù hợp | Demo nhanh, nhúng nội bộ | Người dùng cuối, hỗ trợ khách hàng thực tế |
| Kho dữ liệu Pinecone | Chung index `company-kb` / ns `company` | Chung index `company-kb` / ns `company` |

### 14.8 Vì sao có 2 phiên bản Telegram? (DeepSeek vs Gemini)

Hai file `03-telegram-chatbot.json` (DeepSeek) và `04-telegram-chatbot-gemini.json` (Gemini) có **kiến trúc RAG y hệt nhau** — chỉ khác **model ngôn ngữ** gắn vào AI Agent.

**Kiến trúc này đã chuẩn RAG chưa?** Có. Đây là **Agentic RAG** đúng chuẩn: AI Agent nhận câu hỏi → gọi tool `company_knowledge` (Pinecone retrieve-as-tool) → Gemini Embeddings chuyển câu hỏi thành vector → Pinecone trả về top-5 đoạn liên quan → model tổng hợp câu trả lời chỉ dựa trên ngữ cảnh tìm được. Phần truy xuất (retrieval) hoạt động tốt; lỗi gặp phải **không nằm ở RAG** mà ở **bước model gọi tool**.

**Vấn đề với DeepSeek:** Từ bản DeepSeek V3.2 trở đi, các model có "thinking mode" (suy luận) yêu cầu: mỗi message của model có `tool_calls` khi gửi lại API **phải kèm field `reasoning_content`**. AI Agent của n8n hiện **chưa gửi lại** field này trong vòng gọi tool thứ 2 → DeepSeek trả lỗi:

```
Bad request - please check your parameters.
The reasoning_content in the thinking mode must be passed back to the API.
```

Đây là **lỗi đã biết của n8n** (xem các issue n8n-io/n8n #22579, #29119), xảy ra khi **AI Agent + DeepSeek + gọi tool**. Cách sửa của cộng đồng cần cài community node `n8n-nodes-deepseek-v4-thinking-fix` — nhưng repo này chủ trương **chỉ dùng node built-in**, nên không khuyến khích.

**Giải pháp trong repo này:** Dùng **Google Gemini** (`models/gemini-2.5-flash`) làm model cho AI Agent — Gemini hỗ trợ function/tool calling ổn định, không gặp lỗi trên. Thêm điểm tiện: Gemini **dùng chung credential** `Google Gemini(PaLM) Api account` đã tạo cho Embeddings → **không cần thêm credential mới**.

| Phương án | Ưu | Nhược |
|---|---|---|
| **`04` — Gemini (khuyến nghị)** | Tool calling ổn định; dùng lại credential Gemini; không cài thêm gì | Cần Gemini API key (đã có sẵn cho embedding) |
| `03` — DeepSeek | Chi phí rất rẻ; câu trả lời tự nhiên | **Lỗi `reasoning_content` khi gọi tool** với model thinking mode → cần đổi sang model DeepSeek không-thinking, hoặc cài community node |

> **Tóm lại:** Để chatbot Telegram RAG chạy ngay, hãy dùng **`04-telegram-chatbot-gemini.json`**. Giữ `03` (DeepSeek) làm tài liệu tham khảo / dùng khi n8n đã vá lỗi hoặc khi bạn chọn model DeepSeek không bật thinking mode.

**Gán credentials cho `04`** (giống `03` nhưng thay model):

| Node | Credential |
|------|-----------|
| 3 node Telegram | `Telegram Bot` |
| `🧠 Google Gemini Chat Model` | `Google Gemini(PaLM) Api account` |
| `🔎 RAG: Company Knowledge Base` | `Pinecone account` |
| `🔢 Gemini Embeddings` | `Google Gemini(PaLM) Api account` |
