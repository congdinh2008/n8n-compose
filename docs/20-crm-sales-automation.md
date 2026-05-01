# 20. CRM và Sales Automation

## 📋 Mục lục
- [Tổng quan](#tổng-quan)
- [Lead Management Workflow](#lead-management-workflow)
- [CRM Sync Workflow](#crm-sync-workflow)
- [Sales Pipeline Automation](#sales-pipeline-automation)
- [Follow-up Automation](#follow-up-automation)
- [Lead Scoring](#lead-scoring)
- [Case Studies](#case-studies)
- [Best Practices](#best-practices)

---

## Tổng quan

CRM và Sales automation là một trong những use cases phổ biến nhất của N8N trong doanh nghiệp.

### Vấn đề giải quyết

| Vấn đề | Giải pháp N8N |
|--------|---------------|
| Manual data entry | Auto-sync giữa các hệ thống |
| Missed follow-ups | Automated reminders |
| Lead routing | Auto-assign based on criteria |
| Reporting | Automated daily/weekly reports |
| Data quality | Validation và enrichment |

### Systems thường tích hợp

- **CRM**: HubSpot, Salesforce, Pipedrive, Zoho
- **Email**: Gmail, Outlook
- **Communication**: Slack, Teams
- **Forms**: Google Forms, Typeform, Tally
- **Enrichment**: Clearbit, Apollo, Hunter
- **Calendar**: Google Calendar, Calendly

---

## Lead Management Workflow

### Use Case

Tự động hóa quy trình xử lý lead từ khi submit form đến khi assign cho sales rep.

### Workflow Architecture

```
[Form Submission]
       │
       ▼
[Validate Data]
       │
       ▼
[Enrich Lead Info] ← [Clearbit/Apollo API]
       │
       ▼
[Check Duplicate] ← [CRM Query]
       │
    ┌──┴──┐
    ▼     ▼
[New]  [Existing]
  │       │
  ▼       ▼
[Create] [Update]
  │       │
  └───┬───┘
      ▼
[Assign to Sales Rep]
      │
      ▼
[Send Notifications]
      │
      ▼
[Create Follow-up Task]
```

### Implementation

#### Step 1: Form Submission Trigger

**Node: Webhook**

```json
{
  "name": "Webhook - Lead Form",
  "type": "n8n-nodes-base.webhook",
  "parameters": {
    "httpMethod": "POST",
    "path": "lead-form",
    "responseMode": "lastNode",
    "responseData": "allEntries"
  }
}
```

**Input Data:**

```json
{
  "name": "John Doe",
  "email": "john@company.com",
  "company": "Acme Corp",
  "phone": "+1234567890",
  "message": "Interested in Enterprise plan",
  "source": "website"
}
```

#### Step 2: Validate và Clean Data

**Node: Code**

```javascript
const items = $input.all();

const cleaned = items.map(item => {
  const { json } = item;
  
  // Validate email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(json.email)) {
    throw new Error(`Invalid email: ${json.email}`);
  }
  
  // Clean data
  return {
    json: {
      name: json.name?.trim(),
      email: json.email?.toLowerCase().trim(),
      company: json.company?.trim(),
      phone: json.phone?.replace(/\D/g, ''),
      message: json.message?.trim(),
      source: json.source || 'unknown',
      created_at: new Date().toISOString(),
      status: 'new'
    }
  };
});

return cleaned;
```

#### Step 3: Enrich Lead Data

**Node: HTTP Request (Clearbit API)**

```json
{
  "name": "Enrich - Clearbit",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "https://person.clearbit.com/v2/combined/find",
    "method": "GET",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpBasicAuth",
    "qs": {
      "email": "={{ $json.email }}"
    }
  }
}
```

**Enrichment Data:**

```json
{
  "job_title": "CTO",
  "company_size": "50-200",
  "industry": "Software",
  "linkedin": "https://linkedin.com/in/johndoe",
  "company_domain": "acme.com",
  "company_funding": "$5M Series A"
}
```

#### Step 4: Check Duplicate trong CRM

**Node: HTTP Request (HubSpot API)**

```javascript
// Search for existing contact
const searchResponse = await fetch('https://api.hubapi.com/crm/v3/objects/contacts/search', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${process.env.HUBSPOT_TOKEN}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    filterGroups: [{
      filters: [{
        propertyName: 'email',
        operator: 'EQ',
        value: $json.email
      }]
    }]
  })
});

const exists = searchResponse.results.length > 0;

return {
  json: {
    ...$json,
    is_duplicate: exists
  }
};
```

#### Step 5: Create hoặc Update trong CRM

**Node: If (Branch)**

```
Condition: {{ $json.is_duplicate === false }}

True (New Lead):
  → Create Contact in CRM
  
False (Existing):
  → Update Contact in CRM
```

**Create Contact:**

```json
{
  "name": "Create - HubSpot Contact",
  "type": "n8n-nodes-base.hubspot",
  "parameters": {
    "resource": "contact",
    "operation": "create",
    "properties": {
      "email": "={{ $json.email }}",
      "firstname": "={{ $json.name.split(' ')[0] }}",
      "lastname": "={{ $json.name.split(' ')[1] || '' }}",
      "company": "={{ $json.company }}",
      "phone": "={{ $json.phone }}",
      "lead_source": "={{ $json.source }}",
      "message__c": "={{ $json.message }}"
    }
  }
}
```

#### Step 6: Assign to Sales Rep

**Node: Code (Round Robin)**

```javascript
const salesReps = [
  { name: 'Alice', email: 'alice@company.com', deals: 5 },
  { name: 'Bob', email: 'bob@company.com', deals: 3 },
  { name: 'Charlie', email: 'charlie@company.com', deals: 7 }
];

// Find rep with least deals
const assignedRep = salesReps.reduce((min, rep) => 
  rep.deals < min.deals ? rep : min
);

// Update deal count (in real system, save to DB)
assignedRep.deals++;

return {
  json: {
    ...$json,
    assigned_to: assignedRep.name,
    assigned_email: assignedRep.email
  }
};
```

#### Step 7: Notifications

**Node: Slack**

```json
{
  "name": "Notify - Slack",
  "type": "n8n-nodes-base.slack",
  "parameters": {
    "operation": "post",
    "channel": "sales-leads",
    "text": "🎯 New Lead Assigned",
    "attachments": [
      {
        "fields": [
          { "title": "Name", "value": "={{ $json.name }}" },
          { "title": "Company", "value": "={{ $json.company }}" },
          { "title": "Assigned To", "value": "={{ $json.assigned_to }}" },
          { "title": "Source", "value": "={{ $json.source }}" }
        ]
      }
    ]
  }
}
```

**Node: Email**

```json
{
  "name": "Notify - Email to Rep",
  "type": "n8n-nodes-base.gmail",
  "parameters": {
    "operation": "send",
    "to": "={{ $json.assigned_email }}",
    "subject": "🎯 New Lead Assigned: {{ $json.company }}",
    "emailType": "text",
    "message": "Hi {{ $json.assigned_to }},\n\nNew lead assigned:\n\nName: {{ $json.name }}\nCompany: {{ $json.company }}\nEmail: {{ $json.email }}\n\nPlease follow up within 24 hours."
  }
}
```

---

## CRM Sync Workflow

### Use Case

Đồng bộ dữ liệu giữa các CRM systems hoặc giữa CRM và database nội bộ.

### Workflow

```
[Schedule: Every hour]
       │
       ▼
[Fetch New/Updated from Source CRM]
       │
       ▼
[Fetch New/Updated from Target CRM]
       │
       ▼
[Compare và Identify Changes]
       │
    ┌──┴──┐
    ▼     ▼
[New in Source]  [Updated in Source]
       │                │
       ▼                ▼
[Create in Target]  [Update in Target]
       │                │
       └───────┬────────┘
               ▼
       [Log Sync Results]
```

### Implementation Notes

**Pagination Handling:**

```javascript
// Fetch all records with pagination
async function fetchAll(endpoint, token) {
  let allRecords = [];
  let after = null;
  
  do {
    const response = await fetch(`${endpoint}?after=${after}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await response.json();
    
    allRecords = allRecords.concat(data.results);
    after = data.paging?.next?.after;
  } while (after);
  
  return allRecords;
}
```

**Conflict Resolution:**

```javascript
// Last-write-wins strategy
const resolveConflict = (source, target) => {
  if (new Date(source.updated_at) > new Date(target.updated_at)) {
    return source;
  }
  return target;
};
```

---

## Sales Pipeline Automation

### Use Case

Tự động cập nhật pipeline stages, gửi reminders, tạo reports.

### Workflow 1: Stage Change Notifications

```
[HubSpot: Deal Stage Changed]
       │
       ▼
[Check if Important Stage]
       │
    ┌──┴──┐
    ▼     ▼
[Yes]   [No]
  │      │
  ▼      ▼
[Alert Manager] [Log Only]
```

### Workflow 2: Stale Deal Alerts

```
[Schedule: Daily 9AM]
       │
       ▼
[Query Deals Not Updated in 30 Days]
       │
       ▼
[For Each Deal]
       │
       ▼
[Send Reminder to Owner]
```

### Workflow 3: Weekly Pipeline Report

```
[Schedule: Monday 8AM]
       │
       ▼
[Aggregate Pipeline Data]
       │
       ▼
[Calculate Metrics]
       │
       ▼
[Generate Report]
       │
       ▼
[Send to Management]
```

**Report Generation:**

```javascript
// Pipeline metrics calculation
const deals = $input.all();

const metrics = {
  total_deals: deals.length,
  total_value: deals.reduce((sum, d) => sum + d.json.value, 0),
  by_stage: {},
  avg_days_in_pipeline: deals.reduce((sum, d) => 
    sum + d.json.days_in_pipeline, 0
  ) / deals.length
};

// Group by stage
deals.forEach(deal => {
  const stage = deal.json.stage;
  if (!metrics.by_stage[stage]) {
    metrics.by_stage[stage] = { count: 0, value: 0 };
  }
  metrics.by_stage[stage].count++;
  metrics.by_stage[stage].value += deal.json.value;
});

return { json: metrics };
```

---

## Follow-up Automation

### Use Case

Tự động tạo và quản lý follow-up tasks dựa trên rules.

### Workflow

```
[Schedule: Every 2 hours]
       │
       ▼
[Query Tasks Due Today]
       │
       ▼
[Check Task Status]
       │
    ┌──┴──┐
    ▼     ▼
[Overdue] [Due Today]
    │         │
    ▼         ▼
[Urgent Alert] [Reminder]
```

### Follow-up Sequence

```javascript
// Follow-up rules
const followUpRules = {
  'hot_lead': { interval: 1, unit: 'days' },
  'warm_lead': { interval: 3, unit: 'days' },
  'cold_lead': { interval: 7, unit: 'days' },
  'proposal_sent': { interval: 2, unit: 'days' },
  'negotiation': { interval: 1, unit: 'days' }
};

// Calculate next follow-up
const getNextFollowUp = (leadStatus, lastContactDate) => {
  const rule = followUpRules[leadStatus];
  const nextDate = new Date(lastContactDate);
  nextDate.setDate(nextDate.getDate() + rule.interval);
  return nextDate;
};
```

---

## Lead Scoring

### Use Case

Tự động chấm điểm leads dựa trên criteria.

### Scoring Criteria

| Criteria | Points |
|----------|--------|
| Job Title: C-Level | +20 |
| Job Title: VP/Director | +15 |
| Job Title: Manager | +10 |
| Company Size: 200+ | +15 |
| Company Size: 50-200 | +10 |
| Company Size: <50 | +5 |
| Visited Pricing Page | +10 |
| Downloaded Content | +5 |
| Attended Webinar | +15 |
| Email Opened | +2 |
| Email Clicked | +5 |

### Workflow

```
[Schedule: Daily]
       │
       ▼
[Get All Leads]
       │
       ▼
[Calculate Score for Each]
       │
       ▼
[Update Score in CRM]
       │
       ▼
[If Score > 50: Mark as MQL]
```

**Scoring Code:**

```javascript
const leads = $input.all();

const scored = leads.map(lead => {
  let score = 0;
  const { json } = lead;
  
  // Title scoring
  if (json.job_title?.match(/CEO|CTO|CFO|COO/i)) score += 20;
  else if (json.job_title?.match(/VP|Director/i)) score += 15;
  else if (json.job_title?.match(/Manager/i)) score += 10;
  
  // Company size scoring
  if (json.company_size >= 200) score += 15;
  else if (json.company_size >= 50) score += 10;
  else score += 5;
  
  // Engagement scoring
  if (json.visited_pricing) score += 10;
  if (json.downloaded_content) score += 5;
  if (json.attended_webinar) score += 15;
  
  // Qualification
  const qualification = score >= 50 ? 'MQL' : 'SQL';
  
  return {
    json: {
      ...json,
      lead_score: score,
      qualification
    }
  };
});

return scored;
```

---

## Case Studies

### Case Study 1: SaaS Company

**Công ty**: B2B SaaS, 50 employees
**Vấn đề**: 
- 200+ leads/tháng từ nhiều sources
- Manual data entry tốn 10 giờ/tuần
- Follow-up chậm, miss opportunities

**Giải pháp N8N**:
1. Webhook từ forms → Auto-enrich → Create in HubSpot
2. Round-robin assignment
3. Automated follow-up sequences
4. Slack notifications cho hot leads

**Kết quả**:
- ⬇️ 90% manual work (10h → 1h/tuần)
- ⬆️ 3x faster response time (4h → 15min)
- ⬆️ 25% conversion rate improvement

### Case Study 2: Marketing Agency

**Công ty**: Digital Agency, 20 employees
**Vấn đề**: 
- Leads từ nhiều campaigns không được track
- Không có scoring system
- Reporting manual

**Giải pháp N8N**:
1. Multi-source lead aggregation
2. Auto scoring based on engagement
3. Weekly automated reports

**Kết quả**:
- ⬆️ 40% lead visibility
- ⬇️ 80% reporting time
- ⬆️ 15% ROI tracking accuracy

---

## Best Practices

### Workflow Design

1. ✅ Tách lead management thành nhiều sub-workflows
2. ✅ Luôn validate input data
3. ✅ Handle duplicates
4. ✅ Log tất cả actions
5. ✅ Setup alerts cho failures

### Data Quality

1. ✅ Clean và normalize data trước khi lưu
2. ✅ Enrich data từ external sources
3. ✅ Deduplicate regular
4. ✅ Validate emails, phones
5. ✅ Standardize formats

### Performance

1. ✅ Batch API calls khi có thể
2. ✅ Cache enrichment data
3. ✅ Rate limit external APIs
4. ✅ Monitor execution times
5. ✅ Use queue mode cho volume cao

### Security

1. ✅ Encrypt sensitive data
2. ✅ Rotate API tokens
3. ✅ Limit data logged
4. ✅ Audit trail đầy đủ
5. ✅ Compliance với GDPR/CCPA

---

## 🔗 Tài liệu liên quan

- [21. Marketing Automation](21-marketing-automation.md)
- [25. Data Sync và ETL](25-data-sync-etl.md)
- [40. Best Practices](40-best-practices.md)

---

**[← Quay lại mục lục](README.md)**
