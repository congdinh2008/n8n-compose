# Enterprise: Invoice OCR Vision **v2** — Analytics-ready + Looker Studio Dashboard

> v2 nâng workflow OCR hóa đơn (v1) thành một **pipeline phân tích chuyên nghiệp**: chuẩn hóa schema cho dashboard, kết nối Looker Studio (Google Data Studio), và tự động sinh nhận định AI + cảnh báo bất thường.
>
> Tài liệu này đi kèm 2 file workflow:
> - `workflow-v2.json` — workflow ingestion + OCR (đã làm giàu schema analytics).
> - `workflow-v2-analytics-commentary.json` — workflow chạy theo lịch: tính KPI → Gemini viết nhận định → ghi Commentary/Anomalies + Telegram smart alert.
>
> v1 (`workflow.json` + `GUIDE.md`) vẫn giữ nguyên để tham chiếu.

---

## 1. v2 có gì mới so với v1

| Hạng mục | v1 | v2 |
|---|---|---|
| Schema sheet | 26 cột, log giao dịch thô | **33 cột analytics-ready** (date ISO, VND chuẩn hóa, year/quarter, vendor canonical, confidence bucket, status) |
| Dashboard | Không | **Looker Studio** kết nối Google Sheet |
| Nhận định | Không | **AI Commentary** hằng ngày (Gemini) ghi vào tab Commentary |
| Cảnh báo | Telegram khi hóa đơn lớn | + **Smart alert** chi tiêu tháng bất thường (có context + severity) |
| Chống trùng | Có (theo File ID) | Giữ nguyên |

---

## 2. Kiến trúc tổng thể

```text
[Workflow 1 — Ingestion/OCR]  (workflow-v2.json)
Google Drive Trigger
  -> Cấu Hình
  -> Lọc File Ảnh/PDF Hóa Đơn
  -> Google Sheets: Đọc File Đã Xử Lý   (chống trùng)
  -> Lọc File Chưa Xử Lý
  -> Google Drive: Tải File
  -> Tạo Gemini Vision OCR Request
  -> Gemini Vision: OCR
  -> Parse OCR (33 cột analytics)
  -> Google Sheets: Lưu (tab "Invoice OCR")
  -> Telegram done
       ├─ IF high value (>10tr) -> Telegram alert
       └─ IF giao dịch >30tr     -> Google Sheets: Ghi Anomaly (tab "Anomalies")

           │  (ghi vào cùng 1 Google Sheet)
           ▼
[Google Sheet]  tab: Invoice OCR | Commentary | Anomalies
           │
           ├──────────────► [Looker Studio Dashboard]  (Phase 2, dựng tay)
           │
           ▼
[Workflow 2 — Analytics/Commentary]  (workflow-v2-analytics-commentary.json)
Schedule (6AM hằng ngày)
  -> Cấu Hình
  -> Google Sheets: Đọc Invoice OCR
  -> Tính KPI & Bất Thường (tháng này vs tháng trước, top vendor, anomaly)
  -> Gemini: Viết Nhận Định (tiếng Việt)
  -> Chuẩn Bị Ghi
  -> Google Sheets: Ghi Commentary
  -> IF Có Bất Thường? -> Ghi Anomaly + Telegram smart alert
```

---

## 3. Chuẩn bị Google Sheet (3 tab)

> ⚠️ **Phải là Google Sheet gốc**, KHÔNG phải file Excel `.xlsx` upload lên Drive. File `.xlsx` sẽ gây lỗi `This operation is not supported for this document. The document must not be an Office file.` Nếu đang có `.xlsx`: mở trong Drive → **File → Save as Google Sheets** rồi dùng ID bản mới. Lấy ID từ URL `https://docs.google.com/spreadsheets/d/<ID>/edit`.
>
> 🔁 **Nâng cấp từ v1?** v1 chỉ có 26 cột. n8n map theo **tên cột**, nên 7 cột mới sẽ **không được ghi** nếu sheet thiếu header tương ứng. Hãy **tạo sheet mới** (khuyến nghị) hoặc **thêm đủ 7 header mới** vào sheet cũ. Lưu ý: các dòng cũ (trước khi nâng cấp) sẽ trống `Year Month` / `Total Amount VND` / … nên **không xuất hiện trong KPI v2** cho tới khi tích lũy đủ dữ liệu v2 (workflow commentary có thể báo chi tiêu tháng = 0 trong giai đoạn đầu — đây là bình thường, không phải lỗi).

### Tab 1 — `Invoice OCR` (fact table, 33 cột)

Table Header row (đúng thứ tự, đúng tên — workflow map theo tên cột):

| Processed At | File Name | File ID | File Link | Document Type | Invoice Number | Invoice Date | Invoice Date ISO | Year Month | Quarter | Seller Name | Vendor Canonical | Seller Tax ID | Seller Address | Buyer Name | Buyer Tax ID | Currency | Subtotal | VAT Amount | Discount Amount | Total Amount | Total Amount VND | Payment Method | Line Items JSON | Confidence | Confidence Bucket | Needs Manual Review | Manual Review Reason | High Value | Status | Summary | Gemini Model | Raw OCR JSON |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

Ý nghĩa các cột analytics mới (so với v1):

| Cột | Kiểu | Mục đích phân tích |
|---|---|---|
| `Invoice Date ISO` | Date | Ngày hóa đơn dạng chuẩn `YYYY-MM-DD` (chỉ điền khi chắc chắn, nếu không thì rỗng). **Dùng cho trục thời gian Looker**. Cột `Invoice Date` gốc giữ lại để audit. |
| `Year Month` | Text | `2026-05` — trục drill-down theo tháng |
| `Quarter` | Text | `2026-Q2` — trục drill-down theo quý |
| `Vendor Canonical` | Text | Tên nhà cung cấp đã trim + gộp khoảng trắng → **gom nhóm vendor** đỡ bị trùng lệch. Lưu ý: **giữ nguyên hoa/thường** nên "ACME" và "acme" vẫn tách biệt — đủ tốt khi OCR ghi tên nhất quán; muốn gom chặt hơn thì lowercase trong node Parse. |
| `Total Amount VND` | Number | Tổng tiền **quy về VND** để `SUM` không trộn tiền tệ (USD × tỉ giá; tiền tệ khác để trống) |
| `Confidence Bucket` | Text | `1. <0.5 / 2. 0.5-0.75 / 3. 0.75-0.9 / 4. >=0.9` — đo chất lượng OCR |
| `Status` | Text | `processed / manual_review / ocr_failed` — phân loại để filter dashboard |

### Tab 2 — `Commentary` (11 cột) — workflow 2 ghi vào

| Date | Period | Commentary | Total Spend VND | Invoice Count | Avg Value VND | Delta vs Prev % | Needs Review | OCR Failed | Top Vendor | Generated At |
|---|---|---|---|---|---|---|---|---|---|---|

### Tab 3 — `Anomalies` (8 cột) — workflow 2 ghi khi có bất thường

| Date | Period | Metric | Value VND | Baseline VND | Delta % | Severity | Note |
|---|---|---|---|---|---|---|---|

---

## 4. Credentials & Cấu hình

### Credentials (gán cho cả 2 workflow)

1. **Google Drive OAuth2** — trigger + tải file (workflow 1).
2. **Google Sheets OAuth2** — đọc/ghi sheet (cả 2 workflow).
3. **Google Gemini(PaLM) Api** — OCR + commentary (HTTP Request, credential type `googlePalmApi`).
4. **Telegram Bot** — thông báo/cảnh báo.

### Node `Cấu Hình` của workflow 1 (`workflow-v2.json`)

| Field | Mẫu | Ý nghĩa |
|---|---|---|
| `gemini_model` | `gemini-2.5-flash` | Model OCR |
| `google_sheet_id` | `NHAP_GOOGLE_SHEET_ID` | ID Google Sheet |
| `google_sheet_name` | `Invoice OCR` | Tab fact |
| `high_value_threshold` | `10000000` | Ngưỡng cảnh báo hóa đơn lớn (VND) |
| `telegram_chat_id` | `NHAP_TELEGRAM_CHAT_ID` | Chat nhận thông báo |
| `usd_to_vnd` | `25000` | Tỉ giá USD→VND để quy đổi `Total Amount VND`. ⚠️ Đây là **tỉ giá tĩnh** cho lớp dạy/demo; production nên thay bằng node gọi API tỉ giá rồi đẩy vào field này. |
| `anomaly_txn_threshold` | `30000000` | Ngưỡng **giao dịch lớn**: hóa đơn đơn lẻ vượt mức này sẽ ghi 1 dòng vào tab `Anomalies` (phát hiện ngay khi OCR). |
| `anomalies_sheet_name` | `Anomalies` | Tab ghi anomaly giao dịch lớn (trùng tab với workflow commentary). |

> **Drive folder ID** điền trực tiếp ở node `Google Drive Trigger` (không nằm trong `Cấu Hình` vì trigger chạy trước mọi node).

### Node `Cấu Hình` của workflow 2 (`workflow-v2-analytics-commentary.json`)

| Field | Mẫu | Ý nghĩa |
|---|---|---|
| `google_sheet_id` | `NHAP_GOOGLE_SHEET_ID` | **Cùng Sheet ID** với workflow 1 |
| `fact_sheet_name` | `Invoice OCR` | Tab nguồn để tính KPI |
| `commentary_sheet_name` | `Commentary` | Tab ghi nhận định |
| `anomalies_sheet_name` | `Anomalies` | Tab ghi bất thường |
| `gemini_model` | `gemini-2.5-flash` | Model viết nhận định |
| `telegram_chat_id` | `NHAP_TELEGRAM_CHAT_ID` | Chat nhận smart alert |
| `anomaly_pct_threshold` | `30` | % thay đổi chi tiêu tháng để coi là bất thường |

---

## 5. Phase 2 — Dựng Dashboard Looker Studio (làm tay)

> Nguyên tắc (theo Buổi 10/11): **1 dashboard = 1 audience** (ở đây: Kế toán trưởng / Giám đốc tài chính), top section trả lời trong 30 giây, mọi số có **so sánh**, action-oriented, mobile-friendly.

### Bước 1 — Kết nối
1. Vào [lookerstudio.google.com](https://lookerstudio.google.com) → **Blank Report** → connector **Google Sheets**.
2. Chọn spreadsheet → tab `Invoice OCR` → **Add**.
3. Ở màn data source, chỉnh **kiểu field**:
   - `Invoice Date ISO` → **Date** (YYYY-MM-DD)
   - `Total Amount VND`, `Subtotal`, `VAT Amount`, `Total Amount`, `Confidence` → **Number**
   - `High Value`, `Needs Manual Review` → Boolean/Text
   - ⚠️ `Total Amount VND` có thể bị Looker đoán nhầm thành **Text** (vì có ô trống ở dòng `ocr_failed`/ngoại tệ). **Set thủ công về Number** để `SUM`/`AVG` chạy đúng (ô trống sẽ được coi là null và bị loại khỏi tổng).
4. **Data freshness**: vào Resource → Manage data source → đặt **15 phút** (mặc định 1 giờ).

### Bước 2 — Date range control
- Thêm **Date Range Control** (góc trên), dimension = `Invoice Date ISO`, mặc định `This month` hoặc `Last 30 days`.

### Bước 3 — Scorecards (top KPI, trả lời 30 giây)

> Looker Studio **không** lọc bên trong hàm tổng hợp (vd `COUNT(Status = manual_review)` sẽ báo invalid formula). Cách đúng: tạo **calculated field** dạng cờ 0/1 trước, rồi mới `SUM`/`AVG`.

Tạo 2 calculated field trong data source (Add a field):

```text
needs_review_flag = CASE WHEN Status = "manual_review" THEN 1 ELSE 0 END
high_value_flag   = CASE WHEN High Value THEN 1 ELSE 0 END
```

Tạo 5 Scorecard, mỗi cái bật **Comparison = Previous period**:

| KPI | Metric |
|---|---|
| Tổng chi (VND) | `SUM(Total Amount VND)` |
| Số hóa đơn | Record Count (hoặc `COUNT(File ID)`) |
| Giá trị TB | `AVG(Total Amount VND)` |
| % cần kiểm tra | `AVG(needs_review_flag) * 100` |
| Hóa đơn giá trị lớn | `SUM(high_value_flag)` |

### Bước 4 — Charts (drill-down ≥2 chiều)
- **Time series**: dimension `Invoice Date ISO` (hoặc `Year Month`), metric `Total Amount VND`. Bật drill-down `Quarter → Year Month`.
- **Bar ngang — Top vendor**: dimension `Vendor Canonical`, metric `SUM(Total Amount VND)`, sort desc, limit 10.
- **Cơ cấu chi**: stacked bar/pie theo `Document Type` hoặc `Payment Method`.
- **Chất lượng OCR**: bar theo `Confidence Bucket`, hoặc scorecard `COUNT(Status = ocr_failed)`.
- **Bảng chi tiết + drill-down**: dimensions `Year Month → Vendor Canonical → Invoice Number`, metrics `Total Amount VND`, link `File Link`.

### Bước 5 — Panel Commentary & Anomalies (kết nối workflow 2)
- Thêm **data source thứ 2**: tab `Commentary` → table/text hiển thị dòng **mới nhất** (sort `Generated At` desc, limit 1, show cột `Commentary`).
- Thêm data source `Anomalies` → table màu đỏ/cam, hiển thị các dòng gần đây. Section này trống khi không có bất thường.

### Bước 6 — Filter, style, share
- Dropdown filter: `Vendor Canonical`, `Document Type`, `Status`, `Payment Method`.
- Color coding: đỏ (bad) / vàng (warning) / xanh (good). Layout F-pattern, ≤1 màu chủ đạo nhiều shade.
- **Share** → viewer link; **Schedule email** PDF (vd thứ 2, 7AM) cho stakeholder.

---

## 6. Phase 3 — AI Commentary & Smart Alert (workflow 2)

- **Lịch chạy**: cron `0 6 * * *` (6AM, giờ `Asia/Ho_Chi_Minh`). Đổi tại node `Lịch: Chạy Hằng Ngày`.
- **Tính KPI**: đọc tab `Invoice OCR`, tổng hợp **tháng hiện tại vs tháng trước** (`Year Month`), top vendor theo `Total Amount VND`, đếm `manual_review` / `ocr_failed` / `High Value`.
- **Gemini viết nhận định**: 100–150 từ tiếng Việt, tone analyst, không bịa insight, có action. Có `retryOnFail` + fallback text nếu API lỗi.
- **Ghi `Commentary`**: append 1 dòng/ngày (giữ lịch sử). Looker hiển thị dòng mới nhất.
- **Smart alert**: nếu `|Δ% chi tiêu tháng|` ≥ `anomaly_pct_threshold` (mặc định 30%) → ghi tab `Anomalies` + gửi Telegram (HTML, có context: kỳ, tổng chi, % thay đổi, severity HIGH/MEDIUM, kèm nhận định). Khác **dumb alert** ở chỗ có **ngữ cảnh + mức độ + giải thích**.

> Lưu ý ngày tháng: `Year Month` của fact table và của workflow 2 đều tính **theo chuỗi UTC** (`YYYY-MM`) để khớp nhau tuyệt đối, tránh lệch tháng do timezone.

---

## 6.5 Hai loại Anomaly & cách demo nhanh

Tab `Anomalies` nhận dữ liệu từ **2 nguồn**:

| Loại | Workflow ghi | Điều kiện | Thời điểm | Metric |
|---|---|---|---|---|
| **Giao dịch lớn** | Ingestion (`workflow-v2.json`) | 1 hóa đơn có `Total Amount VND` > `anomaly_txn_threshold` (mặc định 30tr) | **Ngay khi OCR** từng hóa đơn | `Giao dịch lớn` |
| **Chi tiêu tháng bất thường** | Commentary (`workflow-v2-analytics-commentary.json`) | Tổng chi tháng lệch ≥ `anomaly_pct_threshold` (mặc định 30%) so tháng trước | Theo lịch 6AM hằng ngày | `Tổng chi tiêu tháng` |

Severity giao dịch lớn: **HIGH** nếu ≥ 2× ngưỡng (≥60tr), ngược lại **MEDIUM**.

### Demo nhanh (≈1 phút) — anomaly giao dịch lớn
Cách nhanh nhất để thấy tab `Anomalies` có dữ liệu **mà không cần đợi lịch hay tích lũy 2 tháng**:

1. Upload **1 hóa đơn > 30 triệu** vào Drive folder. Mẫu sẵn có: hóa đơn **HD-2026-0007 = 33.000.000 VND** (trang 7 của `sample-invoices/10-sample-invoices.pdf`, hoặc tách riêng từ HTML).
2. Workflow ingestion chạy → ghi `Invoice OCR` → nhánh `IF: Giao Dịch > 30 Triệu?` = true → **append 1 dòng vào `Anomalies`** ngay lập tức.
3. (Tùy chọn) Hạ tạm `anomaly_txn_threshold` xuống ví dụ `2000000` để bất kỳ hóa đơn mẫu nào cũng trigger.

### Demo anomaly chi tiêu tháng (workflow commentary)
Cần có baseline tháng trước:
1. Thêm tay vài dòng vào `Invoice OCR` với `Year Month` = **tháng trước** và `Total Amount VND` nhỏ (vd 5.000.000).
2. Đảm bảo tháng hiện tại đã có dữ liệu lệch ≥ ngưỡng (hoặc hạ tạm `anomaly_pct_threshold` xuống `10`).
3. Mở workflow commentary → **Execute Workflow** (không cần đợi 6AM) → kiểm tra tab `Anomalies` + Telegram.

---

## 7. Phase 4 — Mở rộng khi scale (định hướng, chưa bắt buộc)

- **Text-to-SQL "safe"** (hỏi tiếng Việt với read-only role) **không chạy trên Google Sheets** — cần SQL thật. Khi cần: cho workflow **dual-write** thêm vào **Postgres/BigQuery** song song với Sheets, rồi:
  - Looker Studio connect **BigQuery** (scale >1M dòng — Sheets connector chậm/lỗi khi sheet lớn), hoặc
  - **Metabase** ("Ask Metabot") / lớp NL2SQL với read-only role + schema linking.
- **Mốc nên chuyển backend**: node `Lọc File Đã Xử Lý` đọc **cả sheet mỗi lần poll** — OK với vài nghìn dòng, chậm dần ở **vài chục nghìn**. Đây là điểm nên chuyển dedup + analytics sang SQL.
- **Tỉ giá**: thay `usd_to_vnd` tĩnh bằng node gọi API tỉ giá để `Total Amount VND` chính xác khi có hóa đơn ngoại tệ.

---

## 8. Định nghĩa KPI (KPI dictionary)

| KPI | Công thức | Ghi chú |
|---|---|---|
| Tổng chi | `SUM(Total Amount VND)` | Chỉ tính dòng có VND (USD đã quy đổi; tiền tệ khác bị loại) |
| Số hóa đơn | `COUNT` dòng | Gồm cả dòng `ocr_failed` (đã log) |
| Giá trị TB | Tổng chi / Số hóa đơn | |
| % cần kiểm tra | `manual_review / tổng` | Chất lượng nhập liệu |
| Tỉ lệ lỗi OCR | `ocr_failed / tổng` | Sức khỏe pipeline |
| Δ% chi tiêu | `(tháng này − tháng trước) / tháng trước` | Trigger smart alert |

---

## 9. Cài đặt nhanh (checklist)

1. Tạo Google Sheet gốc + 3 tab với header ở mục 3.
2. Import `workflow-v2.json`, điền node `Cấu Hình` (sheet id, telegram chat id, …) + Drive folder ID ở Trigger, gán 4 credentials.
3. Import `workflow-v2-analytics-commentary.json`, điền node `Cấu Hình` (cùng sheet id), gán credentials, chỉnh giờ chạy nếu cần.
4. Upload vài hóa đơn mẫu (`sample-invoices/`) → kiểm tra tab `Invoice OCR` có dòng + 33 cột.
5. Dựng dashboard Looker Studio theo mục 5.
6. Chạy thử workflow 2 (Execute Workflow) → kiểm tra tab `Commentary` có dòng; nếu Δ% lớn thì có dòng `Anomalies` + Telegram.
7. Bật `Active` cả 2 workflow.

---

## 10. Troubleshooting

| Triệu chứng | Nguyên nhân & cách xử lý |
|---|---|
| `must not be an Office file` (Google Sheets node 400) | Sheet đang là file `.xlsx`. Chuyển sang Google Sheet gốc (mục 3). |
| Looker không vẽ được theo thời gian | Field thời gian map sai. Dùng `Invoice Date ISO` (đã là Date), không dùng `Invoice Date` (chuỗi gốc). |
| Tổng tiền sai/quá lớn | Đang `SUM(Total Amount)` (trộn tiền tệ). Dùng `Total Amount VND`. |
| Commentary trống trên dashboard | Workflow 2 chưa chạy, hoặc table chưa sort `Generated At` desc + limit 1. |
| Telegram lỗi `can't parse entities` | Đã xử lý: HTML + escape `&<>` + `appendAttribution=false`. Nếu vẫn lỗi, kiểm tra chat_id. |
| Số liệu workflow 2 = 0 | `Year Month` ở fact table rỗng (do `Invoice Date ISO` rỗng → fallback ngày xử lý). Kiểm tra OCR có đọc được ngày không. |
| Node `Đọc File Đã Xử Lý` báo **"No output data returned"** và workflow dừng | Sheet `Invoice OCR` đang **trống** (chưa có dòng nào) → Read trả 0 item → deadlock (file đầu tiên không bao giờ được xử lý). **Đã fix sẵn** trong file v2 bằng `Always Output Data = true` trên node này. Nếu đang dùng bản import cũ: mở node → tab **Settings** → bật **Always Output Data**, hoặc import lại `workflow-v2.json`. |
