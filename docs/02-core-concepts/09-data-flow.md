# Data Flow và Binary Data

## 1. Data Structure trong N8N

### Item Structure

Mỗi item trong N8N có cấu trúc:

```json
{
  "json": {
    "field1": "value1",
    "field2": 123,
    "nested": {
      "object": "value"
    }
  },
  "binary": {
    "data": {
      "mimeType": "image/png",
      "data": "base64_encoded_data",
      "fileName": "image.png",
      "fileSize": 12345
    }
  }
}
```

### JSON Data

**Standard data flow:**
```
Node A Output → Node B Input → Node B Output → Node C Input
```

**Example:**
```json
[
  {
    "json": {
      "id": 1,
      "name": "Alice",
      "email": "alice@example.com"
    }
  },
  {
    "json": {
      "id": 2,
      "name": "Bob",
      "email": "bob@example.com"
    }
  }
]
```

---

## 2. Binary Data

### Binary data là gì?

**Binary data** là dữ liệu không phải JSON: files, images, documents, spreadsheets, v.v.

### Binary Data Sources

| Source | Binary Data |
|--------|-------------|
| **HTTP Request** | Downloaded files |
| **Webhook** | File uploads |
| **Google Drive** | Files from Drive |
| **Email** | Attachments |
| **S3** | Objects from S3 |
| **FTP** | Downloaded files |

### Binary Data Structure

```json
{
  "binary": {
    "file": {
      "mimeType": "application/pdf",
      "data": "base64_encoded_content",
      "fileName": "document.pdf",
      "fileSize": 1048576,
      "directory": "/tmp/n8n-binary",
      "fileExtension": "pdf"
    }
  }
}
```

---

## 3. Binary Data Modes

### Memory Mode (Default)

**Pros:**
- Fast
- No disk I/O
- Simple

**Cons:**
- Limited by RAM
- Large files cause issues

**Configuration:**
```bash
N8N_DEFAULT_BINARY_DATA_MODE=memory
```

### Filesystem Mode

**Pros:**
- Handle large files
- Lower memory usage

**Cons:**
- Slower (disk I/O)
- Needs disk space

**Configuration:**
```bash
N8N_DEFAULT_BINARY_DATA_MODE=filesystem
N8N_BINARY_DATA_PATH=/tmp/n8n-binary
```

---

## 4. Working với Binary Data

### Download File

**HTTP Request node:**
```
Response Format: Binary
Destination: Binary
Binary Property Name: file
```

**Result:**
```json
{
  "binary": {
    "file": {
      "mimeType": "application/pdf",
      "data": "...",
      "fileName": "report.pdf"
    }
  }
}
```

### Upload File

**Google Drive node:**
```
Operation: Upload
File: Binary
Binary Property: file
Name: {{ $json.file_name }}
```

### Transform Binary Data

**Code node:**
```javascript
const items = $input.all();

return items.map(item => {
  // Access binary data
  const binaryData = item.binary?.file;
  
  if (binaryData) {
    return {
      json: {
        file_name: binaryData.fileName,
        file_size: binaryData.fileSize,
        mime_type: binaryData.mimeType
      },
      binary: item.binary  // Pass through
    };
  }
  
  return item;
});
```

---

## 5. Binary Data Operations

### Image Processing

```
Download Image → Resize/Convert → Upload
```

**Example flow:**
```
HTTP Request (download image)
  ↓
Code node (process with library)
  ↓
Google Drive (upload processed)
```

### PDF Generation

```
Data → Generate PDF → Save/Email/Upload
```

### File Conversion

```
Download CSV → Convert to Excel → Upload to Drive
```

---

## 6. Data Transformation

### Map Data

```javascript
// Transform structure
const items = $input.all();

return items.map(item => ({
  json: {
    new_field: item.json.old_field,
    computed: item.json.price * item.json.qty,
    formatted: new Date(item.json.date).toLocaleDateString()
  }
}));
```

### Filter Data

```javascript
// Keep only matching items
return $input.all().filter(item => 
  item.json.status === 'active' &&
  item.json.amount > 100
);
```

### Aggregate Data

```javascript
// Combine items
const items = $input.all();
const total = items.reduce((sum, item) => 
  sum + item.json.amount, 0
);

return [{
  json: {
    count: items.length,
    total,
    average: total / items.length
  }
}];
```

---

## 7. Data Flow Patterns

### Pattern 1: Pass-through

```
Node A → Node B → Node C
(Output passes through unchanged)
```

### Pattern 2: Transform

```
Node A → Transform → Node C
(Data structure changes)
```

### Pattern 3: Split

```
Node A → Split → Process A
               → Process B
```

### Pattern 4: Merge

```
Node A → Merge ← Node B
          ↓
      Combined
```

### Pattern 5: Binary + JSON

```
Node A (JSON data) → Node B (adds binary) → Node C (uses both)
```

---

## 8. Large Data Handling

### Pagination

```javascript
// Process in pages
let page = 1;
let allData = [];

while (true) {
  const response = await fetchAPI(page);
  allData = allData.concat(response.data);
  
  if (!response.has_more) break;
  page++;
}

return allData.map(item => ({ json: item }));
```

### Chunking

```javascript
// Process in chunks
const CHUNK_SIZE = 100;
const items = $input.all();

const chunks = [];
for (let i = 0; i < items.length; i += CHUNK_SIZE) {
  chunks.push(items.slice(i, i + CHUNK_SIZE));
}

return chunks[0]; // Process first chunk, loop for rest
```

### Streaming

For very large files, use filesystem mode:
```bash
N8N_DEFAULT_BINARY_DATA_MODE=filesystem
```

---

## 9. Data Validation

### Validate Input

```javascript
const item = $input.first().json;
const errors = [];

if (!item.email) errors.push('Email required');
if (!item.name) errors.push('Name required');
if (item.age && (item.age < 0 || item.age > 150)) {
  errors.push('Invalid age');
}

if (errors.length > 0) {
  throw new Error(`Validation failed: ${errors.join(', ')}`);
}

return $input.all();
```

### Schema Validation

```javascript
const schema = {
  required: ['name', 'email'],
  types: {
    name: 'string',
    email: 'string',
    age: 'number'
  }
};

const item = $input.first().json;
const missing = schema.required.filter(field => !item[field]);

if (missing.length > 0) {
  throw new Error(`Missing fields: ${missing.join(', ')}`);
}
```

---

## 10. Data Debugging

### Inspect Data

**Expression:**
```javascript
// Print full input
{{ JSON.stringify($input.all(), null, 2) }}

// Print keys
{{ Object.keys($input.first().json) }}

// Print binary info
{{ $input.first().binary?.file?.fileName }}
```

### Pin Data

**For testing:**
1. Execute workflow
2. Right-click node
3. "Pin Data"
4. Data persists for future tests

### Export Data

```javascript
// Save to file (Code node)
const fs = require('fs');
const data = $input.all().map(item => item.json);

fs.writeFileSync('/tmp/export.json', JSON.stringify(data, null, 2));

return [{ json: { exported: data.length } }];
```

---

## 11. Common Data Issues

### Issue 1: Lost Data Between Nodes

**Cause:** Node doesn't pass through data

**Fix:** Check node settings, ensure data passthrough enabled

### Issue 2: Binary Data Missing

**Cause:** Binary data not passed through

**Fix:** Ensure binary property is preserved:
```javascript
return {
  json: { ...transformed_data },
  binary: item.binary  // Include binary data
};
```

### Issue 3: Data Type Mismatch

**Cause:** String vs Number confusion

**Fix:** Explicit type conversion:
```javascript
const num = parseInt(item.json.value, 10);
const str = String(item.json.value);
```

### Issue 4: Memory Errors

**Cause:** Too much data in memory

**Fix:** 
- Use filesystem mode for binary
- Process in chunks
- Increase Node.js heap size

---

## 12. Best Practices

### ✅ Do

- Use filesystem mode for large files
- Validate input data
- Handle missing fields gracefully
- Pass through binary data explicitly
- Monitor memory usage
- Use pagination for large datasets
- Clean up temp files

### ❌ Don't

- Load entire large files into memory
- Assume data is always valid
- Forget to pass binary data
- Ignore error cases
- Hardcode file paths
- Skip data validation
- Process everything at once (chunk instead)

---

## 13. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    N8N Data Flow                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│  │ Trigger  │───▶│ Process  │───▶│  Output  │          │
│  │          │    │          │    │          │          │
│  │ JSON     │    │ JSON +   │    │ JSON +   │          │
│  │ Binary   │    │ Binary   │    │ Binary   │          │
│  └──────────┘    └──────────┘    └──────────┘          │
│       │               │               │                 │
│       ▼               ▼               ▼                 │
│  ┌────────────────────────────────────────────┐        │
│  │          Item Array Structure              │        │
│  │  [{ json: {...}, binary: {...} }, ...]     │        │
│  └────────────────────────────────────────────┘        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```
