# 🔧 Workflows v1.1 — Critical Fix Notes

**Ngày fix**: May 13, 2026
**Severity**: 🔴 CRITICAL — v1.0 workflows KHÔNG chạy được

---

## 🐛 Bug trong v1.0

### Triệu chứng HV gặp phải
- Khi import workflow → node Chat Model (Claude / Gemini / DeepSeek) hiện **warning**:
  > _"This node must be connected to an AI chain. Insert one"_
- Khi click "Execute Workflow" → workflow chỉ chạy đến node `Set: Extract Context` (hoặc node ngay trước Chat Model) thì **DỪNG**
- KHÔNG có error rõ ràng, chỉ là execution không reach các node downstream

### Root cause

`@n8n/n8n-nodes-langchain.lmChat*` (Anthropic / GoogleGemini / DeepSeek / OpenAI / etc.) là **sub-nodes**, KHÔNG phải standalone executable nodes.

n8n có 2 loại nodes:

| Loại | Vai trò | Có execute trên main path không? |
|---|---|---|
| **Root nodes** | Basic LLM Chain · AI Agent · Information Extractor · Text Classifier · Sentiment Analysis · Q&A Chain · Summarization Chain | ✅ CÓ — input main, output main |
| **Sub-nodes** | Chat Model (Anthropic / Gemini / DeepSeek / OpenAI / ...) · Memory · Output Parser · Tools | ❌ KHÔNG — chỉ plug vào root node qua specialized inputs (`ai_languageModel`, `ai_memory`, `ai_outputParser`, `ai_tool`) |

→ v1.0 workflows đặt Chat Model node TRÊN main path → n8n không biết phải execute nó như thế nào → bị "stuck" tại node trước đó.

### Tại sao tôi miss bug này

- Sub-node trong UI VẪN có connection points giống main node → dễ nhầm
- Khi build từ JSON template, không có visual warning lúc create
- Validator của n8n chỉ throw warning, không hard error
- **My mistake — should have tested 1 workflow end-to-end ngay từ session đầu, không phải đợi anh report**

---

## ✅ Fix trong v1.1

### Pattern chuyển đổi

**v1.0 (WRONG):**
```
Webhook → Set → [Chat Model] → Code → IF → ...
                    ❌
              standalone trên main path
```

**v1.1 (CORRECT):**
```
Webhook → Set → [Basic LLM Chain] → Code → IF → ...
                       ↑
                       │ ai_languageModel input
                  [Chat Model]
                  (sub-node ở dưới Chain)
```

### Thay đổi cụ thể

Mỗi workflow v1.1 có thêm **Basic LLM Chain root node** (`@n8n/n8n-nodes-langchain.chainLlm`):
- **Position**: Tại vị trí cũ của Chat Model
- **Tên**: `<Provider>: <Task> (Chain)` — e.g., `Gemini: Extract Action Items (Chain)`
- **Parameters**:
  - `promptType: "define"` — không tự đọc chatInput
  - `text`: User prompt được MOVE từ Chat Model sang
  - `messages.messageValues: []` — không system message (giữ pattern đơn giản)

Chat Model node v1.1:
- **Position**: Dời xuống dưới Chain (vị trí sub-node)
- **Tên**: Giữ nguyên (e.g., `Gemini: Extract Action Items`)
- **Parameters**: Giữ `model`, `options`, credentials. **XÓA `messages`** (đã move sang Chain)

### Connection changes

| Connection cũ (v1.0) | Connection mới (v1.1) |
|---|---|
| `Set` --main--> `ChatModel` | `Set` --main--> `Chain` |
| `ChatModel` --main--> `Code` | `Chain` --main--> `Code` |
| (không có) | `ChatModel` --ai_languageModel--> `Chain` |

### Downstream Code nodes compatibility

Code nodes downstream parse output từ Chain với pattern:

```javascript
const response = $input.first().json;
let rawText = '';
if (response.text) {
  rawText = response.text;        // ✅ Chain output format
} else if (response.message?.content) {
  rawText = response.message.content;  // fallback nếu dùng direct API
} else if (response.content) {
  rawText = ...;
}
```

→ Code nodes đã handle `.text` field → **không cần modify** downstream.

---

## 📋 Migration cho HV

### Nếu HV đã import v1.0 và bị stuck

1. Xoá workflow v1.0 (Workflow menu → Delete)
2. Download lại file v1.1 từ Zalo nhóm hoặc folder này
3. Import lại file v1.1
4. Verify thấy có node mới `Chain` trên main path
5. Activate workflow → test với sample input → expect success

### Nếu HV đã build workflow tương tự (custom)

Nếu HV đã build workflow của mình theo pattern v1.0 — fix manual:

1. Mở workflow trong n8n editor
2. Right-click vào Chat Model node → "Disconnect" main connections
3. Add new node → search "Basic LLM Chain" → place trước Code node
4. Copy prompt từ Chat Model node → paste vào Chain `Prompt (User Message)` field
5. Set Chain `Prompt` mode = "Define below"
6. Connect Chat Model vào Chain qua `+ Chat Model` input của Chain
7. Connect upstream node (Set / Code / etc.) → main input của Chain
8. Connect main output của Chain → downstream node
9. Xoá messages trong Chat Model node (Chain handles prompt now)
10. Save + test

---

## 🧪 Test plan v1.1

Trước khi deploy production, HV phải test:

| Step | Action | Expected |
|---|---|---|
| 1 | Import file .json | No warnings |
| 2 | Open workflow, click vào Chain node | Show prompt template đầy đủ |
| 3 | Click vào Chat Model node | Show model + credentials, không có `messages` field |
| 4 | Verify connection: Chat Model → Chain | Connection line từ bottom Chat Model lên Chain |
| 5 | Click "Test workflow" với sample input | All nodes chuyển xanh, no errors |
| 6 | Check output node cuối | Receive expected result |

---

## 🎯 Lesson learned cho cả Trainer + HV

### Cho Trainer

1. **LUÔN test 1 workflow end-to-end** khi build template — không chỉ validate JSON
2. **Khi review HV code** → check pattern: sub-node trên main path = red flag
3. **Dạy concept Root vs Sub-node** trong Buổi 4 từ đầu — tránh confusion

### Cho HV

1. **Sub-nodes** (Chat Model, Memory, Output Parser, Tools) PHẢI plug vào **Root nodes** (Basic LLM Chain, AI Agent, Information Extractor, etc.)
2. **Test ngay** sau khi build node — không build cả workflow xong mới test
3. **Hiểu pattern n8n LangChain**: main flow data, sub-nodes provide capabilities

---

## 📦 Files affected

All **12 workflow files** đã được fix:

| WF | Claude | Gemini | DeepSeek |
|---|---|---|---|
| WF01 | ✅ | ✅ | ✅ |
| WF02 | ✅ | ✅ | ✅ |
| WF03 | ✅ | ✅ | ✅ |
| WF04 | ✅ | ✅ | ✅ |

→ Total 12 files updated to v1.1, all valid + tested structure.

---

## 📝 Workflow name updates

Tất cả 12 workflow name đã thêm suffix ` v1.1` để dễ track:
- `WF01 - Meeting Transcript to Jira + Gmail v1.1`
- `WF01 - Meeting Transcript to Jira + Gmail [Gemini] v1.1`
- ... (etc.)

HV thấy ` v1.1` trong workflow name → confirm đã có fix.

---

**VTI Academy — WAY TO ENTERPRISE**
**v1.1 fix notes — May 13, 2026**
