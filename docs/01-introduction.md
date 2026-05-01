# 📖 Giới thiệu về N8N

## N8N là gì?

**n8n** (đọc là "n-eight-n") là một nền tảng **workflow automation** mã nguồn mở (fair-code), cho phép bạn kết nối các API-enabled applications và tự động hóa quy trình làm việc với minimal code.

### 🔑 Đặc điểm chính

- **Fair-code**: Mã nguồn mở với giấy phép Sustainable Use License
- **Visual workflow editor**: Giao diện kéo thả trực quan
- **300+ tích hợp sẵn**: Built-in nodes cho các service phổ biến
- **Custom code support**: JavaScript và Python cho logic phức tạp
- **Self-hostable**: Chạy trên infrastructure của bạn
- **AI-ready**: Tích hợp LangChain và AI agents

### 🆚 So sánh với các nền tảng khác

| Tính năng | n8n | Zapier | Make (Integromat) |
|-----------|-----|--------|-------------------|
| **Giá cả** | Free (self-hosted) | Trả phí theo task | Trả phí theo operation |
| **Hosting** | Self-hosted hoặc Cloud | Cloud only | Cloud only |
| **Custom code** | ✅ JS + Python | ✅ (Code step) | ✅ |
| **Số lượng nodes** | 300+ | 6000+ | 1500+ |
| **AI/ML** | ✅ LangChain native | ✅ | ✅ |
| **Data privacy** | ✅ Full control | Data trên server họ | Data trên server họ |
| **Complex workflows** | ✅ Excellent | ⚠️ Limited | ✅ Good |

## 🏗️ Kiến trúc

### Core Components

```
┌─────────────────────────────────────────┐
│          n8n Instance                    │
├─────────────────────────────────────────┤
│  ┌───────────┐    ┌──────────────────┐  │
│  │  Editor   │    │  Workflow Engine │  │
│  │   (UI)    │◄──►│   (Execution)    │  │
│  └───────────┘    └──────────────────┘  │
│         │                  │             │
│         ▼                  ▼             │
│  ┌───────────┐    ┌──────────────────┐  │
│  │ Database  │    │    Task Runner   │  │
│  │(SQLite/   │    │  (Code Isolation)│  │
│  │ Postgres) │    └──────────────────┘  │
│  └───────────┘                          │
└─────────────────────────────────────────┘
```

### Execution Models

1. **Main Process**: Xử lý workflow orchestration
2. **Task Runners**: Isolated code execution (JS/Python)
3. **Queue Mode** (production): Distributed execution với Redis

## 🎯 Use Cases

### 🏢 Doanh nghiệp

- **CRM Automation**: Đồng bộ leads giữa các platforms
- **Marketing**: Email campaigns, social media scheduling
- **Sales**: Pipeline management, proposal generation
- **HR**: Employee onboarding, leave management
- **Finance**: Invoice generation, payment tracking
- **Support**: Ticket routing, SLA monitoring

### 👤 Cá nhân

- **Email automation**: Tự động trả lời, phân loại email
- **Social media**: Cross-posting, scheduling
- **Learning**: Content curation, note-taking automation
- **Finance**: Expense tracking, budget alerts
- **Smart home**: IoT device automation

## 📦 Licensing

### Fair-code License

- ✅ **Free** cho self-hosted sử dụng cá nhân và nội bộ
- ✅ **Free** cho revenue dưới $1 triệu USD/năm
- 💰 **Commercial license** required cho doanh nghiệp lớn

### Điều khoản chính

```
Bạn có thể:
✓ Sử dụng miễn phí cho mục đích cá nhân
✓ Self-host cho công ty nhỏ (<$1M revenue)
✓ Modify và customize

Bạn cần license khi:
✗ Enterprise sử dụng (>$1M revenue)
✗ Cung cấp n8n như một service
✗ White-label solution
```

## 🌟 Tại sao chọn N8N?

### ✅ Ưu điểm

1. **Data sovereignty**: Dữ liệu ở lại server của bạn
2. **Cost effective**: Không giới hạn executions (self-hosted)
3. **Flexible**: JavaScript/Python cho complex logic
4. **Transparent**: Có thể audit source code
5. **Community-driven**: Active community và contributions
6. **AI-native**: Built-in LangChain integration

### ⚠️ Hạn chế

1. **Learning curve**: Cao hơn Zapier/Make
2. **Infrastructure**: Cần self-manage (nếu self-hosted)
3. **Support**: Community-based (trừ khi mua enterprise)
4. **Node count**: Ít hơn Zapier nhưng vẫn đủ dùng

## 🚀 Next Steps

→ [Cài đặt và cấu hình N8N](02-installation.md)

## 📚 Tham khảo

- [Official n8n Docs](https://docs.n8n.io)
- [n8n Community](https://community.n8n.io)
- [Workflow Templates](https://n8n.io/workflows/)
- [GitHub Repository](https://github.com/n8n-io/n8n)
