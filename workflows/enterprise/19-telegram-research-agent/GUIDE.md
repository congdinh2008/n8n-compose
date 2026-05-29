# 19 - Telegram Research Agent

> Hệ thống tự động nhận yêu cầu research qua Telegram, phân tích bằng AI, crawl web với Firecrawl, tổng hợp báo cáo Markdown và lưu vào Google Drive.

---

## Mục Lục

1. [Tổng Quan](#1-tổng-quan)
2. [Kiến Trúc Hệ Thống](#2-kiến-trúc-hệ-thống)
3. [Chuẩn Bị](#3-chuẩn-bị)
4. [Cấu Trúc Google Sheet](#4-cấu-trúc-google-sheet)
5. [Workflow 1: Telegram Intake](#5-workflow-1-telegram-intake)
6. [Workflow 2: Research Processor](#6-workflow-2-research-processor)
7. [Cấu Hình Node Set: Config Vars](#7-cấu-hình-node-set-config-vars)
8. [Thiết Lập Credentials](#8-thiết-lập-credentials)
9. [Hướng Dẫn Import và Kích Hoạt](#9-hướng-dẫn-import-và-kích-hoạt)
10. [Kiểm Thử](#10-kiểm-thử)
11. [Tùy Chỉnh Nâng Cao](#11-tùy-chỉnh-nâng-cao)
12. [Xử Lý Sự Cố](#12-xử-lý-sự-cố)

---

## 1. Tổng Quan

### Bài Toán

Việc research thị trường, phân tích sản phẩm hoặc khảo sát ngành thường tốn 4-8 giờ thu thập và tổng hợp thông tin thủ công. Với hệ thống này, bạn chỉ cần gửi một tin nhắn Telegram và nhận về báo cáo hoàn chỉnh sau 5-15 phút.

### Luồng Hoạt Động

```
User gửi Telegram          → Intake Workflow nhận và lưu vào Sheet (queue)
Sheet có yêu cầu mới      → Processor Workflow tự động chạy mỗi 15 phút
AI Agent phân tích         → Gọi Firecrawl search + scrape nhiều nguồn
Gemini tổng hợp báo cáo   → Lưu file .md vào Google Drive folder
Cập nhật Sheet             → Gửi Telegram thông báo với link báo cáo
```

### Kết Quả Đầu Ra

- **Google Sheet** theo dõi trạng thái tất cả yêu cầu
- **Folder Google Drive** riêng cho mỗi báo cáo, đặt tên theo title
- **File Markdown** báo cáo chuyên sâu 2000-3500 từ tiếng Việt
- **Telegram notification** với link trực tiếp khi hoàn thành

---

## 2. Kiến Trúc Hệ Thống

### Workflow 1 — Telegram Intake (`01-telegram-intake.json`)

```
[Telegram Trigger]
      │
      ▼
[IF: Has Text?]
      │ Yes                   │ No
      ▼                       ▼
[Set: Config Vars]    [Telegram: No Text Warning]
      │
      ▼
[Gemini: Parse Request]   ← lmChatGoogleGemini (sub-node)
      │
      ▼
[Code: Build Row Data]
      │
      ▼
[Sheets: Add to Queue]
      │
      ▼
[Telegram: Confirm]
```

### Workflow 2 — Research Processor (`02-research-processor.json`)

```
[Schedule Trigger] ──┐
                     ├──────────────► [Set: Config Vars]
[Manual Trigger]  ───┘                      │
                                            ▼
                                  [Sheets: Get All Rows]
                                            │
                                            ▼
                                  [Code: Filter Queue]
                                            │
                                            ▼
                                    [IF: Has Pending?]
                                    │             │
                                  Yes             No
                                    │             ▼
                                    │     [No Op: No Pending]
                                    ▼
                         [Sheets: Update → Processing]
                                    │
                                    ▼
                            [AI Agent: Research] ─────────┐
                            │  ├─ Gemini Flash (Agent)    │ Error
                            │  ├─ Tool: Firecrawl Search  │
                            │  └─ Tool: Firecrawl Scrape  │
                            │                             ▼
                            ▼                    [Code: Handle Error]
                   [Gemini: Write Report]                 │
                   │  └─ Gemini Flash (Report)            ▼
                   │                          [Sheets: Update → Error]
                   ▼                                      │
           [Code: Prepare Files]                          ▼
                   │                          [Telegram: Notify Error]
                   ▼
          [Drive: Create Folder]
                   │  Error ───────────────► [Code: Handle Error]
                   ▼
         [Code: Save Folder ID]
                   │
                   ▼
          [Drive: Upload Report]
                   │  Error ───────────────► [Code: Handle Error]
                   ▼
         [Code: Build Final Data]
                   │
                   ▼
          [Sheets: Update → Done]
                   │
                   ▼
          [Telegram: Notify Done]
```

### Các Công Nghệ Sử Dụng

| Thành phần | Công nghệ | Vai trò |
|------------|-----------|---------|
| AI Model | Google Gemini 3 Flash Preview | Parse request, Research Agent, Viết báo cáo |
| Web Search | Firecrawl Community Node (`/v2/search`) | Tìm kiếm URLs theo query |
| Web Scrape | Firecrawl Community Node (`/v2/scrape`) | Đọc nội dung đầy đủ từ URL |
| Queue | Google Sheets | Theo dõi trạng thái yêu cầu |
| Storage | Google Drive | Lưu trữ file báo cáo |
| Notification | Telegram Bot API | Nhận yêu cầu & gửi kết quả |

---

## 3. Chuẩn Bị

### 3.1 Tài Khoản Cần Có

- [ ] **Google Account** với Google Sheets và Google Drive
- [ ] **Telegram Bot** (tạo qua @BotFather)
- [ ] **Google Gemini API Key** (Google AI Studio - miễn phí)
- [ ] **Firecrawl API Key** (firecrawl.dev - có gói miễn phí)

### 3.2 Lấy Firecrawl API Key

1. Truy cập [firecrawl.dev](https://firecrawl.dev) → Đăng ký tài khoản
2. Vào Dashboard → API Keys → Copy API Key (dạng `fc-xxxxx`)
3. Gói Free: 500 credits/tháng — đủ cho ~50 lần research

### 3.3 Lấy Google Gemini API Key

1. Truy cập [aistudio.google.com](https://aistudio.google.com)
2. Click **Get API Key** → **Create API Key**
3. Copy API Key để dùng trong n8n credential

### 3.4 Tạo Telegram Bot

```
1. Mở Telegram → Tìm @BotFather
2. Gửi: /newbot
3. Đặt tên bot: Research Assistant Bot
4. Đặt username: research_assist_bot (phải kết thúc bằng _bot)
5. Copy Bot Token: 1234567890:ABCxxxxx
```

---

## 4. Cấu Trúc Google Sheet

### 4.1 Tạo Google Sheet Mới

1. Vào [sheets.google.com](https://sheets.google.com) → Tạo spreadsheet mới
2. Đặt tên: **Research Queue**
3. Đổi tên Sheet 1 thành: **Research Queue**
4. Copy **Sheet ID** từ URL: `https://docs.google.com/spreadsheets/d/**{SHEET_ID}**/edit`

### 4.2 Tạo Header Row (Row 1)

Điền chính xác các tên cột theo thứ tự (A → K):

| Cột | Tên Header | Mô Tả |
|-----|-----------|-------|
| A | `Request_ID` | Mã yêu cầu duy nhất: `REQ-1748526001` |
| B | `Title` | Tiêu đề research do AI trích xuất |
| C | `Raw_Request` | Nội dung tin nhắn gốc từ Telegram |
| D | `Research_Type` | Loại: market_analysis, product_analysis... |
| E | `Chat_ID` | Telegram Chat ID để gửi thông báo |
| F | `User_ID` | Telegram User ID |
| G | `Status` | `queue` / `processing` / `done` / `error` |
| H | `Created_At` | Thời điểm tạo yêu cầu (ISO format) |
| I | `Updated_At` | Thời điểm cập nhật lần cuối |
| J | `Overview` | Tóm tắt ngắn nội dung báo cáo |
| K | `Drive_Folder_Link` | Link folder Google Drive chứa báo cáo |
| L | `Report_Link` | Link trực tiếp file báo cáo |

Table Header Row

| Request_ID | Title | Raw_Request | Research_Type | Chat_ID | User_ID | Status | Created_At | Updated_At | Overview | Drive_Folder_Link | Report_Link |
|------------|-------|-------------|---------------|---------|---------|--------|------------|------------|----------|-------------------|-------------|

> ⚠️ **Quan trọng**: Tên cột phải đúng chính xác (phân biệt hoa/thường) như bảng trên.

### 4.3 Tạo Google Drive Folder Gốc

1. Vào [drive.google.com](https://drive.google.com) → Tạo folder mới
2. Đặt tên: **Research Reports**
3. Copy **Folder ID** từ URL: `https://drive.google.com/drive/folders/**{FOLDER_ID}**`

---

## 5. Workflow 1: Telegram Intake

### Mô Tả Từng Node

#### Node 1: Telegram Trigger
- **Mục đích**: Lắng nghe tin nhắn từ Telegram Bot
- **Cấu hình**: Update type = `message`
- **Credential**: Telegram Research Bot (Bot Token)

#### Node 2: IF: Has Text?
- **Mục đích**: Lọc chỉ xử lý tin nhắn có text, bỏ qua ảnh/file/sticker
- **Điều kiện**: `$json.message?.text` không rỗng
- **True** → Tiếp tục xử lý | **False** → Gửi hướng dẫn

#### Node 3: Set: Config Vars ⭐
- **Mục đích**: Khai báo tất cả biến cấu hình dùng chung
- **PHẢI ĐIỀN**: `SHEET_ID`, `SHEET_NAME`, `DRIVE_ROOT_FOLDER_ID`, `RESEARCH_SOURCES`
- Xem chi tiết tại [Mục 7](#7-cấu-hình-node-set-config-vars)

#### Node 4: Gemini: Parse Request
- **Mục đích**: AI phân tích tin nhắn, trích xuất title và loại research
- **Input**: `$json.text` (tin nhắn của user)
- **Output JSON**: `{ title, research_type, language }`

#### Node 5: Code: Build Row Data
- **Mục đích**: Tạo `Request_ID` (timestamp-based), chuẩn bị data cho Sheet
- **Logic**: Parse JSON từ Gemini, tạo `REQ-{timestamp}`, set `status = 'queue'`

#### Node 6: Sheets: Add to Queue
- **Mục đích**: Ghi yêu cầu vào Google Sheet với status `queue`
- **Operation**: Append Row

#### Node 7: Telegram: Confirm
- **Mục đích**: Xác nhận đã nhận yêu cầu, thông báo ID để theo dõi
- **Message mẫu**:
  ```
  ✅ Đã nhận yêu cầu research!
  ID: REQ-1748526001
  Chủ đề: Phân tích thị trường xe điện Việt Nam 2025
  Trạng thái: Đang xếp hàng chờ xử lý
  ```

---

## 6. Workflow 2: Research Processor

### Mô Tả Từng Node

#### Node 1 & 2: Schedule Trigger + Manual Trigger
- **Schedule**: Chạy tự động mỗi **15 phút** (cấu hình trong node)
- **Manual**: Dùng để test hoặc trigger ngay lập tức khi cần
- Cả hai đều kết nối **trực tiếp** vào `Set: Config Vars` (không qua Merge)
- n8n cho phép nhiều nguồn kết nối vào cùng 1 node input

#### Node 3: Set: Config Vars ⭐
- **Mục đích**: Khai báo biến cấu hình cho Processor
- Ngoài SHEET_ID và DRIVE, còn có **RESEARCH_SOURCES** và các tham số điều chỉnh độ sâu research

#### Node 5: Sheets: Get All Rows
- **Mục đích**: Đọc toàn bộ Google Sheet để lọc queue
- **Operation**: Read (returnAllMatches: true)

#### Node 6: Code: Filter Queue
- **Mục đích**: Lọc rows có `Status = 'queue'`, sort theo `Created_At` (oldest first)
- **Output**: Row đầu tiên cần xử lý, hoặc `{has_pending: false}` nếu rỗng

#### Node 7: IF: Has Pending?
- **True** → Tiếp tục xử lý | **False** → `No Op: No Pending` (dừng)

#### Node 8: Sheets: Update → Processing
- **Mục đích**: Đánh dấu `Status = 'processing'` trước khi AI chạy
- **Quan trọng**: Ngăn chặn việc workflow khác xử lý trùng lặp row này

#### Node 9: AI Agent: Research ⭐⭐
- **Mục đích**: Trung tâm của hệ thống — AI quyết định khi nào search và scrape
- **Model**: Gemini 2.5 Flash Preview (via `lmChatGoogleGemini`)
- **Tools**:
  - `/search in Firecrawl`: Tìm kiếm URLs theo keyword
  - `/scrape in Firecrawl2`: Đọc nội dung đầy đủ từ URL
- **maxIterations**: 15 (tối đa 15 lần gọi tools)
- **System Prompt** hướng dẫn:
  - Tạo 4-5 keywords tiếng Việt + tiếng Anh
  - Bước 2: Dùng /search in Firecrawl với từng keyword, chọn URLs uy tín
  - Bước 4: Dùng /scrape in Firecrawl2 để đọc nội dung 4-5 URLs tốt nhất
  - Tổng hợp findings, số liệu, sources

#### Node 10 & 11: Tool: Firecrawl Search / Scrape
- **Loại**: `n8n-nodes-firecrawl.firecrawl` — Community node chính thức của Firecrawl
- **Cần cài**: `@mendable/n8n-nodes-firecrawl` qua n8n Community Nodes
- **Search**: operation=`search`, query=`$fromAI(...)`
- **Scrape**: operation=`scrape`, url=`$fromAI(...)`
- **Credential**: `firecrawlApi` (API Key từ firecrawl.dev)
- **API version**: v2 (node tự handle, không cần config thêm)
- **AI Tool support**: ✅ `usableAsTool: true` — kết nối trực tiếp qua `ai_tool` output vào AI Agent

#### Node 12: Gemini: Write Report
- **Mục đích**: Tổng hợp toàn bộ research data thành báo cáo Markdown hoàn chỉnh
- **Input**: `$json.output` từ AI Agent (toàn bộ findings đã thu thập)
- **Output**: Báo cáo Markdown 2000-3500 từ theo format chuẩn

#### Node 13: Code: Prepare Files
- **Mục đích**: Convert nội dung text sang binary để upload Drive
- **Logic**:
  ```javascript
  Buffer.from(reportMarkdown, 'utf-8').toString('base64')
  // → binary field "reportFile" với mimeType: text/markdown
  ```
- Tạo tên folder: `REQ-xxx - Title - YYYY-MM-DD`

#### Node 14: Drive: Create Folder
- **Mục đích**: Tạo folder mới trong `DRIVE_ROOT_FOLDER_ID`
- **API**: `POST https://www.googleapis.com/drive/v3/files`
- **Body**: `{ name, mimeType: 'application/vnd.google-apps.folder', parents: [rootFolderId] }`

#### Node 15: Code: Save Folder ID
- **Mục đích**: Lưu folder ID từ Drive API response, tạo folder link
- **Lưu ý**: Binary data được lấy từ `Code: Prepare Files` (không phải node trước đó)

#### Node 16: Drive: Upload Report
- **Mục đích**: Upload file `.md` vào folder vừa tạo
- **Node type**: `n8n-nodes-base.googleDrive` (native node, operation: upload)
- **Input**: Binary field `reportFile` từ Code: Prepare Files
- **inputDataFieldName**: hardcoded `reportFile` (không dùng expression)

#### Node 17: Code: Build Final Data
- **Mục đích**: Lấy `fileId` và `webViewLink` từ Drive upload response

#### Node 18: Sheets: Update → Done
- **Mục đích**: Cập nhật row: `Status = done`, điền Overview, Drive_Folder_Link, Report_Link
- **Match**: Theo `Request_ID`

#### Node 19: Telegram: Notify Done
- **Mục đích**: Gửi thông báo hoàn thành với link trực tiếp tới báo cáo

#### Error Handling Nodes
- **AI Agent, Drive Create, Drive Upload** đều có `onError: continueErrorOutput`
- **Code: Handle Error**: Gom lỗi, format thông báo
- **Sheets: Update → Error**: Đổi status sang `error`
- **Telegram: Notify Error**: Báo user biết có sự cố

---

## 7. Cấu Hình Node Set: Config Vars

### Workflow 1 — Set: Config Vars

| Biến | Giá Trị Cần Điền | Ví Dụ |
|------|-----------------|-------|
| `SHEET_ID` | ID của Google Sheet | `1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms` |
| `SHEET_NAME` | Tên sheet tab | `Research Queue` |
| `DRIVE_ROOT_FOLDER_ID` | ID folder Drive gốc | `1_abc123defghijklmnop` |
| `RESEARCH_SOURCES` | Danh sách domain ưu tiên | Xem bên dưới |

### Workflow 2 — Set: Config Vars (thêm các biến)

| Biến | Giá Trị Cần Điền | Ví Dụ |
|------|-----------------|-------|
| `SHEET_ID` | Giống WF1 | _(như trên)_ |
| `SHEET_NAME` | Giống WF1 | `Research Queue` |
| `DRIVE_ROOT_FOLDER_ID` | Giống WF1 | _(như trên)_ |
| `RESEARCH_SOURCES` | Danh sách nguồn ưu tiên | Xem bên dưới |
| `MAX_SEARCH_RESULTS` | Số kết quả search mỗi query | `8` |
| `TOP_URLS_TO_SCRAPE` | Số URLs scrape tối đa | `5` |
| `REPORT_LANGUAGE` | Ngôn ngữ báo cáo | `Vietnamese` |

### Tùy Chỉnh RESEARCH_SOURCES

Đây là danh sách các domain mà AI sẽ **ưu tiên tìm kiếm** khi search. Có thể tùy chỉnh theo lĩnh vực:

**Mặc định (đa lĩnh vực):**
```
vnexpress.net,cafef.vn,tuoitre.vn,thanhnien.vn,mof.gov.vn,gso.gov.vn,statista.com,reuters.com,bloomberg.com,techcrunch.com,mckinsey.com,deloitte.com
```

**Chuyên thị trường Việt Nam:**
```
cafef.vn,vnexpress.net,vietstock.vn,dantri.com.vn,mof.gov.vn,gso.gov.vn,nhandan.vn,vneconomy.vn
```

**Chuyên công nghệ:**
```
techcrunch.com,theverge.com,wired.com,arstechnica.com,zdnet.com,techradar.com,pcmag.com
```

**Chuyên tài chính/đầu tư:**
```
bloomberg.com,reuters.com,ft.com,wsj.com,economist.com,cafef.vn,tinnhanhchungkhoan.vn
```

---

## 8. Thiết Lập Credentials

### 8.1 Google Sheets OAuth2

1. n8n → **Credentials** → **Add Credential** → `Google Sheets OAuth2 API`
2. Đăng nhập Google Account có quyền truy cập Sheet
3. **Tên credential**: `Google Sheets` (khớp với placeholder trong workflow)

### 8.2 Google Drive OAuth2

1. n8n → **Credentials** → **Add Credential** → `Google Drive OAuth2 API`
2. Đăng nhập **cùng Google Account** như Sheets
3. **Tên credential**: `Google Drive`

> 💡 **Mẹo**: Bạn có thể dùng chung 1 OAuth2 app cho cả Sheets và Drive nếu cấu hình đúng scopes.

### 8.3 Google Gemini (Google Palm API)

1. n8n → **Credentials** → **Add Credential** → `Google PaLM API`
2. Điền **API Key** lấy từ Google AI Studio
3. **Tên credential**: `Google Gemini`

### 8.4 Telegram Bot

1. n8n → **Credentials** → **Add Credential** → `Telegram API`
2. Điền **Bot Token** lấy từ @BotFather (dạng: `1234567890:ABCxxxxx`)
3. **Tên credential**: `Telegram Research Bot`

### 8.5 Firecrawl (Community Node + Credential)

**Bước 1: Cài Community Node**
1. n8n UI → **Settings** → **Community Nodes** → **Install**
2. Package name: `@mendable/n8n-nodes-firecrawl`
3. Đồng ý cài → Chờ khởi động lại (auto)

> ⚠️ Yêu cầu: n8n ≥ 1.79.0 và `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true` (đã có trong docker-compose)

**Bước 2: Tạo Credential Firecrawl**
1. n8n → **Credentials** → **Add Credential** → `Firecrawl API`
2. **API Key**: Dán key từ [firecrawl.dev](https://firecrawl.dev) Dashboard (dạng `fc-xxxxx`)
3. **Base URL**: Giữ mặc định `https://api.firecrawl.dev/v2`
4. **Tên credential**: `Firecrawl API`

---

## 9. Hướng Dẫn Import và Kích Hoạt

### 9.1 Import Workflows

```
n8n UI → Workflows → Import from File
→ Chọn: 01-telegram-intake.json
→ Lặp lại với: 02-research-processor.json
```

### 9.2 Gán Credentials

Sau khi import, với **mỗi workflow**:

1. Mở workflow → Click vào từng node có icon ⚠️ (chưa có credential)
2. Chọn credential tương ứng từ dropdown
3. Nhấn **Save**

Danh sách nodes cần gán credential:

**Workflow 1:**
| Node | Credential Type |
|------|----------------|
| Telegram Trigger | Telegram Research Bot |
| Gemini Flash (Parse) | Google Gemini |
| Sheets: Add to Queue | Google Sheets |
| Telegram: Confirm | Telegram Research Bot |
| Telegram: No Text Warning | Telegram Research Bot |

**Workflow 2:**
| Node | Credential Type |
|------|----------------|
| Gemini Flash (Agent) | Google Gemini |
| Gemini Flash (Report) | Google Gemini |
| Tool: Firecrawl Search | Firecrawl API |
| Tool: Firecrawl Scrape | Firecrawl API |
| Sheets: Get All Rows | Google Sheets |
| Sheets: Update → Processing | Google Sheets |
| Sheets: Update → Done | Google Sheets |
| Sheets: Update → Error | Google Sheets |
| Drive: Create Folder | Google Drive |
| Drive: Upload Report | Google Drive |
| Telegram: Notify Done | Telegram Research Bot |
| Telegram: Notify Error | Telegram Research Bot |

### 9.3 Điền Config Vars

Trong **mỗi workflow**, mở node **Set: Config Vars** và điền giá trị thực:
- `SHEET_ID` → ID từ URL Google Sheet
- `DRIVE_ROOT_FOLDER_ID` → ID folder Drive
- `RESEARCH_SOURCES` → Tùy chỉnh nếu cần

### 9.4 Kích Hoạt

1. Mở **Workflow 1** (Telegram Intake) → Toggle **Active** (góc phải màn hình)
2. Mở **Workflow 2** (Research Processor) → Toggle **Active**

---

## 10. Kiểm Thử

### 10.1 Test Workflow 1 (Intake)

1. Mở Telegram → Tìm bot của bạn → /start
2. Gửi tin nhắn thử:
   ```
   Phân tích thị trường xe điện Việt Nam 2025: tiềm năng, đối thủ, cơ hội đầu tư
   ```
3. **Kết quả kỳ vọng**:
   - Bot trả lời xác nhận với Request ID
   - Google Sheet có row mới với status `queue`

4. Gửi thêm vài yêu cầu khác:
   ```
   Phân tích sản phẩm iPhone 16 Pro Max: điểm mạnh, điểm yếu, đối thủ cạnh tranh
   ```
   ```
   Báo cáo ngành thương mại điện tử ASEAN: thị phần, xu hướng 2025-2030
   ```

### 10.2 Test Workflow 2 (Processor)

**Cách 1: Manual Trigger** (khuyến nghị khi test lần đầu)
1. Mở Workflow 2 → Click **Test workflow**
2. Click vào node **Manual Trigger** → **Execute Node**
3. Quan sát từng node thực thi trong n8n UI

**Cách 2: Đợi Schedule** (15 phút)
- Workflow tự chạy, kiểm tra trong **Executions** tab

**Theo dõi quá trình xử lý:**
1. Google Sheet → Row chuyển từ `queue` → `processing` → `done`
2. Google Drive → Xuất hiện folder mới: `REQ-xxx - Title - YYYY-MM-DD`
3. Trong folder: file `report-REQ-xxx.md`
4. Telegram → Nhận thông báo với link Drive

### 10.3 Kiểm Tra Nội Dung Báo Cáo

Mở file `.md` trong Google Drive, báo cáo phải có đầy đủ:
- [ ] Tiêu đề và metadata (ngày, loại, trạng thái)
- [ ] Tóm Tắt Điều Hành (3-5 bullet points)
- [ ] Bối Cảnh & Tổng Quan
- [ ] Phân Tích Chi Tiết với số liệu
- [ ] Dữ Liệu & Số Liệu (bảng hoặc danh sách)
- [ ] Xu Hướng & Cơ Hội
- [ ] Rủi Ro & Thách Thức
- [ ] Kết Luận & Khuyến Nghị (3-5 điểm)
- [ ] Nguồn Tham Khảo (danh sách URLs)

---

## 11. Tùy Chỉnh Nâng Cao

### 11.1 Thay Đổi Schedule

Mở node **Schedule Trigger** → Thay đổi interval:

| Nhu cầu | Cấu hình |
|---------|---------|
| Mỗi 5 phút | field: minutes, interval: 5 |
| Mỗi 30 phút | field: minutes, interval: 30 |
| Mỗi giờ | field: hours, interval: 1 |

### 11.2 Điều Chỉnh Độ Sâu Research

Trong node **AI Agent: Research**, thay đổi system prompt:

```
Tạo 4-5 search queries    → nhiều queries hơn: 6-8
scrape 4-5 URLs           → ít hơn: 2-3 (tiết kiệm Firecrawl credits)
maxIterations: 15         → ít hơn: 6-8 (chạy nhanh hơn)
```

### 11.3 Thay Đổi Gemini Model

Trong cả `Gemini Flash (Parse)`, `Gemini Flash (Agent)` và `Gemini Flash (Report)`:
- Model mặc định: `models/gemini-3-flash-preview`
- Sau khi import, mở từng node → trường **Model** → verify hoặc chọn model từ dropdown
- Xem danh sách model tại: [Google AI Studio](https://aistudio.google.com)

### 11.4 Thêm Nguồn Ưu Tiên

Trong `Set: Config Vars`, cập nhật `RESEARCH_SOURCES`:

```
Thêm nguồn chuyên ngành Y tế:
→ suckhoedoisong.vn,bacsigiadinhhanoi.vn,who.int,nih.gov

Thêm nguồn chuyên ngành Bất Động Sản:
→ batdongsan.com.vn,cenhomes.vn,homedy.com,savills.com.vn
```

### 11.5 Thay Đổi Format Báo Cáo

Trong node **Gemini: Write Report**, sửa prompt để thay đổi cấu trúc báo cáo. Ví dụ thêm section SWOT Analysis:

```markdown
## Phân Tích SWOT
| | Tích Cực | Tiêu Cực |
|--|---------|---------|
| Nội bộ | **Strengths** | **Weaknesses** |
| Ngoại cảnh | **Opportunities** | **Threats** |
```

### 11.6 Gửi Báo Cáo Qua Email (Mở Rộng)

Thêm node Gmail sau **Sheets: Update → Done**:
- Attach file báo cáo
- Gửi đến email người yêu cầu (cần thêm cột Email vào Sheet)

---

## 12. Xử Lý Sự Cố

| Sự Cố | Nguyên Nhân | Cách Khắc Phục |
|-------|-------------|----------------|
| Bot không phản hồi | Workflow 1 chưa Active hoặc sai Bot Token | Kiểm tra Active, verify Bot Token trong credential |
| Row không xuất hiện trong Sheet | Sai SHEET_ID hoặc SHEET_NAME | Copy lại SHEET_ID từ URL, đảm bảo tên sheet khớp chính xác |
| AI Agent báo lỗi tool | Firecrawl API Key sai hoặc hết credits | Kiểm tra key trên dashboard firecrawl.dev |
| Drive folder không tạo được | Sai DRIVE_ROOT_FOLDER_ID hoặc thiếu quyền | Verify Folder ID, đảm bảo Google account có quyền write |
| File upload thất bại | Drive quota hoặc thiếu quyền | Kiểm tra Drive storage, verify OAuth2 scope |
| Status mắc kẹt ở "processing" | Lỗi mid-run không được catch | Xem Executions trong n8n, thủ công sửa status trong Sheet về "queue" |
| Báo cáo quá ngắn | maxOutputTokens quá thấp | Tăng `maxOutputTokens` của `Gemini Flash (Report)` lên 8192 |
| Báo cáo không có nguồn | Agent không scrape đủ | Tăng `maxIterations` lên 20+, kiểm tra Firecrawl credits |
| Telegram không nhận notification | Sai Chat ID trong Sheet | Chat ID phải là số nguyên (ví dụ: `-1001234567890` cho group) |
| Lỗi "Cannot read property text" | Gemini trả về response không có trường `text` | Kiểm tra model name đúng format `models/gemini-3-flash-preview` |

### Cách Debug Nhanh

1. **Xem execution log**: n8n UI → Executions → Click vào execution gần nhất
2. **Kiểm tra node output**: Click vào từng node trong execution → xem data đầu ra
3. **Test riêng từng node**: Click vào node → "Execute Node" để test với data thực
4. **Kiểm tra Firecrawl**: Test API trực tiếp tại [firecrawl.dev/playground](https://firecrawl.dev)
5. **Reset stuck row**: Vào Sheet, tìm row status=`processing`, sửa thủ công về `queue`

---

## Ghi Chú Kỹ Thuật

### Tại Sao Dùng AI Agent Thay Vì Linear Pipeline?

- **Linh hoạt**: Agent tự quyết định query nào cần thiết, URL nào đáng scrape
- **Thích ứng**: Với mỗi chủ đề khác nhau, agent điều chỉnh chiến lược tìm kiếm
- **Hiệu quả**: Không lãng phí Firecrawl credits vào URLs không liên quan

### Tại Sao Có 2 Gemini Model Nodes?

- `Gemini Flash (Agent)`: Phục vụ AI Agent với maxIterations cao, cần stable
- `Gemini Flash (Report)`: Phục vụ chainLlm để viết báo cáo, cần `maxOutputTokens` cao

Trong n8n, mỗi LLM Chain/Agent cần kết nối `ai_languageModel` riêng — không dùng chung được.

### Error Handling Strategy

- `onError: continueErrorOutput` trên AI Agent và Drive nodes → kích hoạt output thứ 2
- Output thứ 2 kết nối vào `Code: Handle Error` → chuẩn hóa error data
- Sau đó cập nhật Sheet status=`error` và notify Telegram để user biết
- Ngăn chặn row bị "stuck" ở `processing` mãi mãi

---

*Workflow được thiết kế cho n8n Community Edition, chạy trên Docker Compose. Mô hình AI: Google Gemini 2.5 Flash Preview.*
