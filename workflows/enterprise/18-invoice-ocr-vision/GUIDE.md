# Enterprise: Invoice OCR Vision từ Google Drive sang Google Sheets

## Mục tiêu

Workflow này xử lý hóa đơn do nhân viên upload vào một Google Drive folder:

- Tự động phát hiện file ảnh/PDF mới trong Drive folder
- Tải file bằng Google Drive node built-in
- Gửi ảnh/PDF sang Gemini Vision qua HTTP Request node built-in
- Parse JSON OCR và lưu vào Google Sheets
- Báo Telegram khi đọc xong từng file
- Gửi cảnh báo riêng nếu tổng tiền lớn hơn `10,000,000 VND`

## Vì sao dùng node này cho n8n Community

Workflow chỉ dùng node có sẵn trong n8n Community:

| Mục đích | Node dùng | Lý do |
|---|---|---|
| Theo dõi folder upload | Google Drive Trigger | Built-in trigger, chạy polling khi workflow active |
| Tải ảnh/PDF | Google Drive | Built-in file download, trả binary data cho node sau |
| OCR Vision bằng Gemini | HTTP Request | Ổn định nhất cho multimodal `inlineData` từ binary; không cần community package ngoài |
| Chuẩn hóa dữ liệu | Code | Xử lý JSON, số tiền, logic cảnh báo |
| Lưu kết quả | Google Sheets | Built-in append row |
| Thông báo | Telegram | Built-in send message |

Không dùng node AI Agent/LangChain cho phần OCR vì bài toán cần gửi binary ảnh/PDF trực tiếp vào Gemini API. HTTP Request giúp kiểm soát payload `contents.parts.inlineData`, `responseMimeType: application/json`, timeout và parsing rõ ràng hơn.

Nguồn tham khảo:

- n8n Google Drive Trigger: https://docs.n8n.io/integrations/builtin/trigger-nodes/n8n-nodes-base.googledrivetrigger/
- n8n Google Drive Download file: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.googledrive/file-operations/
- n8n Google Sheets: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.googlesheets/
- Gemini `generateContent`: https://ai.google.dev/api/generate-content

## Luồng xử lý

```text
Google Drive Trigger
  -> Cấu Hình
  -> Lọc File Ảnh/PDF Hóa Đơn
  -> Google Sheets: Đọc File Đã Xử Lý   (chống trùng)
  -> Lọc File Chưa Xử Lý                (bỏ file đã có trong sheet)
  -> Google Drive: Tải File Hóa Đơn
  -> Tạo Gemini Vision OCR Request
  -> Gemini Vision: OCR Hóa Đơn
  -> Parse Gemini OCR Result
  -> Google Sheets: Lưu Kết Quả OCR
  -> Telegram: Báo Đã Đọc Xong
  -> IF: Tổng Tiền > 10 Triệu?
      -> Telegram: Cảnh Báo Hóa Đơn Lớn
```

## File trong package

| File | Mô tả |
|---|---|
| `workflow.json` | Workflow import vào n8n |
| `sample-invoices/sample-invoices.csv` | 10 hóa đơn mẫu dạng dữ liệu |
| `sample-invoices/sample-invoices.html` | 10 mẫu hóa đơn có thể mở/print/screenshot để upload test |
| `sample-invoices/10-sample-invoices.pdf` | PDF 10 trang sinh từ HTML, upload thẳng lên Drive để test |

## Chuẩn bị Google Sheet

Tạo Google Sheet với sheet name: `Invoice OCR`

Header row:

| Processed At | File Name | File ID | File Link | Document Type | Invoice Number | Invoice Date | Seller Name | Seller Tax ID | Seller Address | Buyer Name | Buyer Tax ID | Currency | Subtotal | VAT Amount | Discount Amount | Total Amount | Payment Method | Line Items JSON | Confidence | Needs Manual Review | Manual Review Reason | High Value | Summary | Gemini Model | Raw OCR JSON |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

## Credentials cần có

1. `Google Drive OAuth2`
   - Dùng cho Google Drive Trigger và Google Drive Download.
   - Credential phải có quyền đọc folder nhận hóa đơn.

2. `Google Sheets OAuth2`
   - Dùng để append row vào Sheet.

3. `Google Gemini(PaLM) Api account`
   - Lấy API key tại Google AI Studio.
   - Dùng trong HTTP Request node với predefined credential type `googlePalmApi`.

4. `Telegram Bot`
   - Dùng để gửi thông báo.
   - Tạo bot bằng BotFather và lấy `chat_id` của nhóm/người nhận.

## Cấu hình tập trung (node `Cấu Hình`)

Toàn bộ tham số cấu hình nằm ở **một** node Set tên `Cấu Hình` (ngay sau Trigger). Không cần tạo n8n Variables, không hard-code rải rác. Mở node này và sửa 5 giá trị:

| Field | Ý nghĩa | Giá trị mẫu |
|---|---|---|
| `gemini_model` | Model Gemini dùng để OCR | `gemini-2.5-flash` |
| `google_sheet_id` | ID của Google Sheet lưu kết quả | `NHAP_GOOGLE_SHEET_ID` |
| `google_sheet_name` | Tên sheet (tab) trong file | `Invoice OCR` |
| `high_value_threshold` | Ngưỡng cảnh báo hóa đơn lớn (VND) | `10000000` |
| `telegram_chat_id` | Chat/Group ID nhận thông báo | `NHAP_TELEGRAM_CHAT_ID` |

Các node phía sau (Build request, Google Sheets, Telegram) đều đọc qua `$('Cấu Hình').first().json.<field>` nên chỉ cần sửa ở đây.

> Lưu ý: **Drive folder ID** không nằm trong node `Cấu Hình` mà phải điền trực tiếp ở node Trigger, vì trigger chạy trước mọi node khác nên không thể tham chiếu ngược về node Set.

## Cài đặt workflow

1. Import `workflows/enterprise/18-invoice-ocr-vision/workflow.json`.
2. Mở node `Cấu Hình` và điền: `google_sheet_id`, `telegram_chat_id` (bắt buộc); chỉnh `gemini_model`, `google_sheet_name`, `high_value_threshold` nếu cần.
3. Mở node `Google Drive Trigger: Ảnh Hóa Đơn Mới`, điền `folderToWatch.value` bằng Google Drive folder ID nhận hóa đơn.
4. Gán credentials cho các node Google Drive, Google Sheets, Gemini và Telegram.
5. Upload 1 ảnh/PDF hóa đơn vào folder để test.
6. Khi test ổn, bật `Active`.

## Test với 10 hóa đơn mẫu

Mở file:

```text
workflows/enterprise/18-invoice-ocr-vision/sample-invoices/sample-invoices.html
```

Hoặc upload trực tiếp file PDF có sẵn:

```text
workflows/enterprise/18-invoice-ocr-vision/sample-invoices/10-sample-invoices.pdf
```

Nếu dùng HTML:

1. Print từng hóa đơn thành PDF hoặc chụp màn hình thành PNG/JPG.
2. Upload file vào Google Drive folder đang được workflow theo dõi.
3. Kiểm tra Google Sheet có row mới.
4. Kiểm tra Telegram nhận thông báo.
5. Với các hóa đơn trên 10 triệu, kiểm tra có thêm cảnh báo.

## Output chính

Workflow cố gắng chuẩn hóa các trường:

- `invoice_number`
- `invoice_date`
- `seller_name`, `seller_tax_id`, `seller_address`
- `buyer_name`, `buyer_tax_id`
- `subtotal`, `vat_amount`, `discount_amount`, `total_amount`
- `payment_method`
- `line_items`
- `confidence`
- `needs_manual_review`

## Lưu ý vận hành

- Workflow xử lý theo lô: nếu một lần polling phát hiện nhiều file mới, tất cả file hợp lệ đều được OCR, ghi Sheet và thông báo riêng từng file (không bị bỏ sót file thứ 2 trở đi).
- Node Gemini tự retry 3 lần khi lỗi tạm thời (mạng, 429, 503). Nếu một file vẫn lỗi sau retry, file đó được ghi vào Sheet với `Needs Manual Review = true` và lý do lỗi, đồng thời gửi Telegram cảnh báo đọc thất bại — các file còn lại trong lô vẫn được xử lý bình thường.
- Thông báo Telegram dùng `parse_mode=HTML` và đã escape ký tự `&`, `<`, `>` trong dữ liệu OCR để tránh lỗi `can't parse entities` khi tên nhà cung cấp hoặc mô tả chứa các ký tự này.
- Manual execution của Google Drive Trigger có thể chỉ trả event gần nhất hoặc báo lỗi nếu chưa có event phù hợp; khi workflow active, trigger sẽ polling đều.
- Nên yêu cầu nhân viên upload ảnh rõ, đủ 4 góc hóa đơn, không bị lóa.
- Nếu hóa đơn nhiều trang, ưu tiên upload PDF thay vì nhiều ảnh rời.
- Nếu hóa đơn viết tay hoặc ảnh mờ, workflow vẫn lưu row nhưng `Needs Manual Review` có thể là `true`.
- **Chống xử lý trùng (built-in):** trước khi tải file, workflow đọc cột `File ID` trong sheet (node `Google Sheets: Đọc File Đã Xử Lý`, chạy 1 lần nhờ Execute Once) và bỏ qua mọi file đã có ID trong sheet (node `Lọc File Chưa Xử Lý`). Nhờ vậy cùng một file sẽ không bị OCR lại khi workflow re-run hoặc trigger polling lại — tiết kiệm lượt gọi Gemini. Dedup theo **Drive File ID**, nên file re-upload (Drive cấp ID mới) vẫn được coi là file mới; muốn chặn theo nội dung thì đổi key dedup sang `Invoice Number`.
- Bắt buộc giữ đúng tên cột `File ID` trong header sheet để cơ chế chống trùng hoạt động (sheet trống/chỉ có header thì coi như chưa có file nào, mọi file đều mới).
