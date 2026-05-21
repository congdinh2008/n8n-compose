# 📧 Enterprise: Outlook & Slack Email Inbox Manager

> **Hệ thống tự động hóa quản lý hộp thư Outlook chuyên nghiệp qua Slack, phân loại email thông minh và cho phép thao tác xử lý nhanh (Đọc, Lưu trữ, Gắn cờ) trực tiếp từ giao diện chat Slack.**
> **Phiên bản:** 1.1.0
> **Cập nhật:** 2026-05-21

---

## 🎯 Mục Tiêu

Workflow giúp tối ưu hóa quy trình quản lý email công việc thông qua tích hợp hai chiều (dual-loop) giữa Microsoft Outlook và Slack:
1. **Lắng nghe email mới:** Nhận diện email ngay khi cập nhật trong hộp thư Outlook qua Microsoft Graph API.
2. **Phân loại thông minh (Classification):** Tự động lọc email dựa trên VIP senders, keywords khẩn cấp và loại trừ email rác, quảng cáo, tin bản tin (newsletter).
3. **Tương tác hai chiều qua Slack (Interactivity):**
   - Đối với email quan trọng: Gửi thông báo chi tiết dạng **Slack Block Kit** kèm các nút bấm tương tác: **Lưu trữ 📦**, **Đọc ✅**, **Gắn cờ ⭐️**.
   - Đối với email thường: Thông báo nhẹ nhàng dạng text.
   - Đối với email rác/quảng cáo: Tự động lưu trữ và đánh dấu đã đọc trên Outlook mà không cần làm phiền người dùng.
4. **Cập nhật trạng thái tức thời:** Khi người dùng click nút trên Slack, n8n thực thi hành động tương ứng trên Outlook và cập nhật giao diện tin nhắn Slack (xóa các nút để tránh click lặp, bổ sung badge hiển thị người xử lý và thời gian xử lý).

---

## 👥 Đối Tượng Sử Dụng

| Đối tượng | Mô tả |
|-----------|-------|
| **Cá nhân bận rộn** | Muốn đạt trạng thái **Inbox Zero** mà không cần liên tục chuyển đổi giữa ứng dụng Mail và Slack. |
| **Quản lý / Team Lead** | Nhận các cảnh báo email khẩn cấp từ khách hàng VIP và xử lý ngay lập tức từ thiết bị di động thông qua ứng dụng Slack. |
| **Đội ngũ Vận hành / Support** | Phối hợp xử lý hòm thư chung, người này xử lý xong thì giao diện Slack của cả team sẽ cập nhật trạng thái "Đã đọc/Đã lưu trữ bởi @User". |

---

## 🗺️ Sơ Đồ Luồng

### Loop 1: Nhận Email & Phân Loại
```
[ Outlook Trigger: Email Mới ]
             │
             ▼
      [ Classify Email ]
    (VIP / Keywords / Type)
             │
             ▼
      [ Switch Action ]
      /      │       \
     /       │        \
 (Important) (Promo) (Normal)
   /         │          \
  ▼          ▼           ▼
[ Slack:    [ Outlook:  [ Slack:
Interactive  Auto-Arc    Quiet
 Alert ]    & MarkRead]  Alert ]
```

### Loop 2: Slack Interactivity (Phản Hồi Hai Chiều)
```
[ Slack Button Click: Archive/Read/Flag ]
                   │
                   ▼
     [ Slack Interactivity Webhook ]
                   │
                   ▼
         [ Parse Slack Payload ]
                   │
                   ▼
          [ Switch Action Slack ]
          /        │         \
         /         │          \
   (Archive)   (Mark Read)   (Flag)
     /             │            \
    ▼              ▼             ▼
[ Outlook:     [ Outlook:     [ Outlook:
 Archive ]     Mark Read ]   Add Category]
    \              │             /
     \             │            /
      ▼            ▼           ▼
       [ Prepare Slack Update ]
    (Xóa nút bấm, thêm badge trạng thái)
                   │
                   ▼
        [ Update Slack Message ]
      (Gửi POST đến response_url)
```

---

## 📊 Nodes Chi Tiết

| # | Node | Type | Mô tả |
|---|------|------|-------|
| 1 | **Outlook Trigger (New Email)** | Microsoft Outlook Trigger | Trigger khi có email unread mới trong Inbox |
| 2 | **Config Vars** | Set | Cấu hình biến tập trung cho toàn bộ workflow (Ví dụ: `slackChannelId`) |
| 3 | **Classify Email** | Code | Phân loại email dựa trên VIP senders và bộ lọc từ khóa tiếng Việt |
| 4 | **Switch Action** | Switch | Điều hướng xử lý dựa trên phân loại của email |
| 5 | **Code: Build Slack Blocks** | Code | Tạo cấu trúc JSON Block Kit cho tin nhắn có nút tương tác |
| 6 | **Slack: Interactive Alert** | HTTP Request | Gọi Slack API trực tiếp để gửi tin nhắn có Block Kit tương tác |
| 7 | **Outlook: Auto Archive** | Microsoft Outlook | Tự động chuyển email quảng cáo/newsletter vào Archive |
| 8 | **Outlook: Mark Read (Auto)** | Microsoft Outlook | Đánh dấu đã đọc cho email tự động lưu trữ |
| 9 | **Slack: Quiet Alert** | Slack | Gửi thông báo text ngắn gọn cho email thường |
| 10| **Slack Interactivity Webhook** | Webhook | Lắng nghe hành động nhấn nút từ Slack gửi về |
| 11| **Parse Slack Payload** | Code | Parse JSON payload của Slack (URL-encoded) |
| 12| **Switch Action Slack** | Switch | Điều hướng hành động do người dùng chọn trên Slack |
| 13| **Outlook Action: Archive** | Microsoft Outlook | Di chuyển email sang thư mục Archive trên Outlook |
| 14| **Outlook Action: Mark Read** | Microsoft Outlook | Đánh dấu email đã đọc trên Outlook |
| 15| **Outlook Action: Add Category**| Microsoft Outlook | Gắn nhãn Category "⭐ Important" cho email trên Outlook |
| 16| **Prepare Slack Update** | Code | Build lại Blocks mới (xóa nút, thêm trạng thái xử lý) |
| 17| **Update Slack Message** | HTTP Request | Gửi HTTP POST phản hồi thay thế tin nhắn gốc trên Slack |

---

## 🔑 Credentials Cần Chuẩn Bị

### 1. Microsoft Graph API OAuth2 (Outlook)
Để n8n tương tác với hộp thư của bạn, cần tạo một ứng dụng trên cổng thông tin Microsoft Entra ID (Azure Portal).

1. Truy cập [Microsoft Entra admin center](https://entra.microsoft.com/) hoặc [Azure Portal](https://portal.azure.com/).
2. Chọn **App registrations** → **New registration**.
   - **Name**: `n8n Outlook Manager`
   - **Supported account types**: Chọn `Accounts in any organizational directory (Any Microsoft Entra ID tenant - Multitenant) and personal Microsoft accounts (e.g. Skype, Xbox)` để dùng được cả tài khoản cá nhân (@outlook.com, @hotmail.com) và doanh nghiệp.
   - **Redirect URI**: Chọn nền tảng `Web` và điền URL callback từ n8n của bạn:
     *Ví dụ:* `https://<ten-mien-n8n-cua-ban>.trycloudflare.com/rest/oauth2-credential/callback` hoặc `https://your-n8n-domain.com/rest/oauth2-credential/callback`.
3. Sau khi đăng ký, hãy copy các thông tin sau:
   - **Application (client) ID**
   - **Directory (tenant) ID** (thường dùng `common` cho tài khoản cá nhân).
4. Vào mục **Certificates & secrets** → **Client secrets** → **New client secret** → Đặt tên và chọn thời gian hết hạn → Nhấn **Add** → Copy ngay **Value** của secret (giá trị này chỉ hiển thị một lần).
5. Vào mục **API permissions** → **Add a permission** → **Microsoft Graph** → **Delegated permissions** → Chọn các quyền sau:
   - `offline_access` (để lấy refresh token)
   - `Mail.Read` và `Mail.ReadWrite` (để đọc và chỉnh sửa trạng thái email)
   - `Mail.Send` (nếu muốn mở rộng tính năng gửi email trả lời tự động)
   - Nhấn **Add permissions**.
6. **Cấu hình trên n8n:**
   - Trong n8n dashboard, tạo Credential loại **Microsoft Outlook OAuth2**.
   - Điền **Client ID**, **Client Secret**, **Tenant ID** (hoặc để mặc định `common`).
   - Nhấn **Connect** và đăng nhập tài khoản Microsoft của bạn để cấp quyền.

---

### 2. Slack App & Interactivity
Để gửi tin nhắn tương tác Block Kit và nhận phản hồi khi click nút bấm.

1. Truy cập [Slack API Apps](https://api.slack.com/apps) → Nhấn **Create New App** → **From scratch**.
   - **App Name**: `Outlook Inbox Bot`
   - Chọn Slack Workspace của bạn.
2. Vào mục **OAuth & Permissions**:
   - Thêm Redirect URI nếu cần thiết.
   - Tại mục **Scopes** -> **Bot Token Scopes** thêm các quyền:
     - `chat:write` (để gửi tin nhắn thông báo)
     - `chat:write.public` (để gửi tin nhắn vào các kênh công khai mà bot chưa tham gia)
     - `incoming-webhook` (tuỳ chọn)
   - Cuộn lên đầu trang OAuth & Permissions và nhấn **Install to Workspace** → Nhấn **Allow** → Copy **Bot User OAuth Token** (bắt đầu bằng `xoxb-`).
3. Vào mục **Interactivity & Shortcuts** (Rất quan trọng!):
   - Bật toggle **Interactivity** sang **ON**.
   - Điền URL Webhook của n8n vào ô **Request URL**:
     *Cú pháp:* `https://<ten-mien-n8n-cua-ban>/webhook/slack-interactive-outlook`
     *Lưu ý:* Cần sử dụng Production URL của webhook n8n (không sử dụng localhost, sử dụng URL của cloudflared tunnel nếu bạn đang chạy local).
     *Ví dụ:* `https://n8n-tunnel.trycloudflare.com/webhook/slack-interactive-outlook`.
   - Nhấn **Save Changes** ở dưới cùng.
4. **Cấu hình trên n8n:**
   - Tạo Credential loại **Slack API** trong n8n và nhập **Bot User OAuth Token** của bạn.

---

## 🛠️ Cài Đặt Step-by-Step

### Bước 1: Import Workflow
1. Mở n8n Dashboard → Chọn **Add Workflow** (góc trên bên phải).
2. Nhấn nút menu ba chấm → Chọn **Import from File**.
3. Chọn file workflow bạn muốn dùng:
   - `workflows/enterprise/14-outlook-slack-inbox/workflow.json` (Phiên bản xử lý bằng Code - Không cần API AI)
   - `workflows/enterprise/14-outlook-slack-inbox/workflow-deepseek.json` (Phiên bản sử dụng DeepSeek AI để phân loại)
   - `workflows/enterprise/14-outlook-slack-inbox/workflow-gemini.json` (Phiên bản sử dụng Google Gemini AI để phân loại)

### Bước 2: Liên kết Credentials & Cấu hình biến tập trung
Mở từng node sau và cấu hình:
- **Outlook Trigger (New Email)**: Chọn Microsoft Outlook account.
- **Config Vars**: Mở node này và nhập ID của kênh Slack vào giá trị của biến `slackChannelId` (ví dụ: `#inbox-alerts` hoặc ID kênh dạng `C0123456789`). ID này sẽ được dùng chung cho tất cả các thông báo gửi đi.
- **Slack: Interactive Alert**: Chọn HTTP Header Auth với cấu hình Token là `Bearer xoxb-YOUR-BOT-TOKEN` (Slack Bot Token).
- **Slack: Quiet Alert**: Chọn Slack API account. (Lưu ý: Node này sẽ tự lấy `slackChannelId` từ cấu hình ở trên).
- **Outlook Action: Archive**, **Outlook Action: Mark Read**, **Outlook Action: Add Category**: Chọn cùng Microsoft Outlook account đã tạo.
- *(Dành riêng cho bản AI)* **DeepSeek Chat Model / Gemini Chat Model**: Tạo và chọn credential API key tương ứng.

### Bước 3: Cấu hình Webhook URL trên Slack
1. Lấy URL Webhook từ node **Slack Interactivity Webhook**.
   - Nhấp vào node này → Chọn tab **Webhook URLs**.
   - Copy **Production URL** (ví dụ: `https://n8n.domain.com/webhook/slack-interactive-outlook`).
   - *Lưu ý:* Nếu chạy n8n local thông qua Cloudflare Tunnel (`cloudflared`), hãy đảm bảo URL sử dụng domain tunnel public, ví dụ: `https://xxxx.trycloudflare.com/webhook/slack-interactive-outlook`.
2. Dán URL này vào mục **Interactivity & Shortcuts** của Slack App trên Slack Console như hướng dẫn ở bước trên.

### Bước 4: Test & Kích Hoạt
1. Gửi một email test có độ ưu tiên cao hoặc chứa từ khóa khẩn cấp đến hòm thư Outlook của bạn.
2. Click **Test Workflow** trong n8n.
3. Chờ email kích hoạt trigger → Kiểm tra tin nhắn Block Kit hiển thị trên Slack.
4. Thử click một nút bất kỳ (ví dụ: **Lưu trữ 📦**) trên Slack:
   - Kiểm tra email trên Outlook xem đã được di chuyển sang thư mục **Archive** chưa.
   - Kiểm tra tin nhắn trên Slack xem các nút bấm có biến mất và cập nhật trạng thái `"🟢 Trạng thái: 📦 Đã lưu trữ (Archived) | Người xử lý: @username lúc hh:mm:ss"` chưa.
5. Sau khi test thành công, bật toggle **Active** (ở góc trên bên phải n8n UI) sang **ON** để chạy tự động.

---

## 📡 Slack Block Kit Reference

Khi một nút bấm được nhấn, Slack gửi một payload chứa thông tin hành động. Dưới đây là cấu trúc Block Kit được định nghĩa trong node `Slack: Interactive Alert`:

```json
[
  {
    "type": "header",
    "text": {
      "type": "plain_text",
      "text": "📧 Outlook Inbox Manager",
      "emoji": true
    }
  },
  {
    "type": "section",
    "text": {
      "type": "mrkdwn",
      "text": "*Email quan trọng mới!* 🔴\n\n*Người gửi:* {{ $json.from?.emailAddress?.name }} <{{ $json.from?.emailAddress?.address }}>..."
    }
  },
  {
    "type": "actions",
    "elements": [
      {
        "type": "button",
        "text": { "type": "plain_text", "text": "Lưu trữ 📦" },
        "style": "primary",
        "value": "{{ $json.id }}",
        "action_id": "archive"
      },
      ...
    ]
  }
]
```

> [!TIP]
> Thuộc tính `value` của nút bấm lưu trữ ID duy nhất của email (`{{ $json.id }}`). Khi Slack gửi payload về Webhook, n8n sẽ trích xuất trường này để biết chính xác cần thao tác trên email nào. Điều này tránh việc phải lưu trữ trạng thái trung gian trong cơ sở dữ liệu.

---

## ⚠️ Lưu Ý Community Version

- **Hạn chế Token Hết Hạn:** N8n community quản lý refresh token của OAuth2 thông qua cơ sở dữ liệu local (thường là SQLite). Nếu n8n bị tắt lâu hoặc file database bị lỗi, bạn có thể phải cấp lại quyền (reconnect) cho Microsoft Outlook. Nên cấu hình n8n sử dụng cơ sở dữ liệu PostgreSQL cho môi trường production ổn định.
- **Xử lý Webhook Local:** Khi chạy n8n trên máy cá nhân, các dịch vụ bên ngoài như Slack không thể gửi yêu cầu đến `http://localhost:5678`.
  - **Giải pháp:** Sử dụng Cloudflare Tunnel (`cloudflared tunnel --url http://localhost:5678`) như đang chạy trong môi trường của bạn để tạo một đường hầm an toàn HTTPS trỏ về máy local. Sử dụng URL HTTPS này để cấu hình Request URL trong Slack App Console.
- **Concurrency & Rate Limit:** Microsoft Graph API có giới hạn số lượng request (throttling). Tránh loop quá nhiều email cùng một lúc để tránh bị khóa API tạm thời.

---

## 🔒 Security Notes

- **Xác thực Webhook từ Slack:** Nhằm tránh kẻ xấu giả mạo request gửi tới webhook n8n của bạn, hãy kiểm tra **Signature** của Slack.
  - Mỗi request từ Slack đều đi kèm header `X-Slack-Signature` và `X-Slack-Request-Timestamp`.
  - Bạn có thể cấu hình thêm một bước validate chữ ký bằng `Signing Secret` của Slack App trong node Code hoặc bật tính năng verify signature nếu có.
- **Bảo mật API Credentials:** Tuyệt đối không để lộ Client Secret của Azure App hoặc Slack Bot Token trong code. Luôn lưu trữ chúng bằng hệ thống **Credentials** tích hợp sẵn của n8n.

---

## 🐛 Troubleshooting

| Triệu chứng | Nguyên nhân khả dĩ | Giải pháp xử lý |
|-------------|--------------------|-----------------|
| **Outlook Trigger không chạy** | Token OAuth2 bị hết hạn hoặc không có quyền `Mail.Read` | Mở Credentials của n8n, nhấn Connect lại và đảm bảo đã check đồng ý tất cả các scope quyền yêu cầu. |
| **Không nhận được payload từ Slack** | URL trong Slack Interactivity sai hoặc đang dùng `localhost` | Kiểm tra lại URL trong trang thiết lập Slack App. Đảm bảo dùng link HTTPS public (ví dụ domain của Cloudflare Tunnel). |
| **Lỗi "Slack payload parsing"** | Header content-type là url-encoded nhưng Code node parse trực tiếp dạng JSON | Đảm bảo Code node dùng hàm `JSON.parse(body.payload)` để giải mã vì Slack đóng gói dữ liệu dạng Form Data. |
| **Tin nhắn Slack không cập nhật trạng thái** | `response_url` hết hạn hoặc không gửi đúng định dạng | Slack `response_url` chỉ có hiệu lực trong 30 phút. Định dạng gửi đi phải là JSON chứa `replace_original: true` và mảng `blocks` mới. |
| **Lỗi 403 Forbidden khi di chuyển email** | Thư mục "Archive" không tồn tại hoặc tài khoản không có quyền ghi | Tạo sẵn thư mục Archive trong tài khoản Outlook của bạn, hoặc cấu hình đổi folderId thành ID thư mục cụ thể. |

---

## 🚀 Hướng Mở Rộng

1. **Ứng Dụng AI Tóm Tắt & Gợi Ý Phản Hồi:**
   Sau node phân loại, chuyển nội dung email qua node **AI (Gemini 2.0 Flash / DeepSeek)** để:
   - Tóm tắt email thành 3 gạch đầu dòng ngắn gọn gửi lên Slack.
   - Tự động soạn thảo 3 phương án trả lời nhanh dạng nút bấm (ví dụ: "Đồng ý", "Từ chối", "Cần thêm thời gian"). Khi click, n8n tự động reply email bằng nội dung tương ứng.
2. **Theo Dõi Tiến Độ Trên Google Sheets:**
   Lưu log tất cả hành động xử lý email (Thời gian nhận, Người gửi, Tiêu đề, Hành động thực hiện, Người xử lý, Thời gian xử lý) vào một Google Sheet chung để đo lường KPI xử lý email của team hỗ trợ.
3. **Chuyển Thành Task Trên Trello/Jira:**
   Bổ sung thêm nút bấm "Tạo Task 📋" trên Slack Block Kit. Khi nhấn nút này, n8n sẽ tự động tạo một thẻ công việc trên Trello hoặc Jira chứa nội dung email để theo dõi tiến độ công việc.

---

## 📁 Cấu Trúc Files

```
enterprise/14-outlook-slack-inbox/
├── workflow.json         # File cấu hình n8n workflow tiêu chuẩn (JS Code classification)
├── workflow-deepseek.json # Phiên bản sử dụng DeepSeek AI
├── workflow-gemini.json  # Phiên bản sử dụng Google Gemini AI
└── GUIDE.md              # File tài liệu hướng dẫn sử dụng (file này)
```

---

## 📋 Changelog

| Phiên bản | Ngày cập nhật | Nội dung thay đổi |
|-----------|---------------|-------------------|
| **1.1.0** | 2026-05-21    | Thêm node `Config Vars` để quản lý biến tập trung (`slackChannelId`). Thay thế node Slack v2.1 bằng node HTTP Request cho tính năng Interactive Message để sửa lỗi serialize Block Kit. Ra mắt 2 phiên bản AI phân loại bằng DeepSeek và Gemini. |
| **1.0.0** | 2026-05-21    | Khởi tạo workflow quản lý Outlook & Slack tương tác hai chiều. |

---
**Tạo bởi:** 2026-05-21
**Phiên bản:** 1.1.0
**Tác giả:** Teaching Collection - n8n Vietnam
