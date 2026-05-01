# 👤 Personal Productivity

## 1. Email Management

### Inbox Zero Automation

**Use Case:** Tự động phân loại và xử lý email

```
Gmail Trigger (New Email)
    │
    ▼
Classify Email (AI/Code)
    │
    ├──[Newsletter]──► Label + Archive
    │
    ├──[Promotion]───► Label + Mute
    │
    ├──[Important]───► Star + Notify
    │
    └──[Spam]────────► Delete
```

**Classification Logic:**
```javascript
const email = $input.first().json;

let category = 'normal';

// Newsletter patterns
const newsletterKeywords = ['unsubscribe', 'newsletter', 'digest'];
if (newsletterKeywords.some(kw => email.subject.toLowerCase().includes(kw))) {
  category = 'newsletter';
}

// Promotion patterns
const promoKeywords = ['sale', 'discount', '% off', 'limited offer'];
if (promoKeywords.some(kw => email.subject.toLowerCase().includes(kw))) {
  category = 'promotion';
}

// Important patterns
const vipSenders = ['boss@company.com', 'important-client@corp.com'];
if (vipSenders.includes(email.from)) {
  category = 'important';
}

return [{ json: { ...email, category } }];
```

### Auto-Reply Assistant

**Use Case:** Draft auto-replies cho common emails

```
Gmail Trigger
    │
    ▼
IF needs reply? (AI check)
    │
    └──[Yes]──► Generate Draft (AI)
                │
                ▼
            Save as Draft
                │
                ▼
            Notify User
```

---

## 2. Task Management

### Daily Task Digest

**Use Case:** Tổng hợp tasks cần làm trong ngày

```
Schedule (8 AM daily)
    │
    ├──► Fetch Todoist Tasks
    ├──► Fetch Google Calendar Events
    └──► Fetch Notion Tasks
         │
         ▼
    Merge & Prioritize
         │
         ▼
    Send Morning Briefing (Email/Telegram)
```

**Morning Briefing:**
```javascript
const tasks = $node["Todoist"].all().map(i => i.json);
const events = $node["Calendar"].all().map(i => i.json);
const notion = $node["Notion"].all().map(i => i.json);

const briefing = {
  date: $now.format('yyyy-MM-dd'),
  tasks: {
    urgent: tasks.filter(t => t.priority === 'urgent').length,
    today: tasks.filter(t => t.due === 'today').length,
    overdue: tasks.filter(t => t.overdue).length
  },
  events: events.filter(e => e.date === $now.format('yyyy-MM-dd')),
  focus_items: notion.slice(0, 3)
};

return [{ json: briefing }];
```

### Capture to Task Manager

**Use Case:** Quick capture từ nhiều sources

```
Multiple Triggers:
  ├── Slack Message to self
  ├── Email to tasks@domain.com
  ├── Voice memo (transcribed)
  └── Telegram message
       │
       ▼
  Parse & Format
       │
       ▼
  Create in Todoist/Notion
       │
       ▼
  Confirm via Notification
```

---

## 3. Note-Taking & Knowledge

### Web Clipper to Notes

**Use Case:** Lưu articles đọc sau

```
Browser Bookmarklet/Extension
    │
    ▼
Webhook (URL + content)
    │
    ▼
Extract Key Points (AI)
    │
    ▼
Save to Notion/Obsidian
    │
    ▼
Tag & Categorize
    │
    ▼
Add to Reading List
```

### Meeting Notes Automation

**Use Case:** Auto-generate meeting notes

```
Calendar Trigger (Meeting ended)
    │
    ▼
Get Meeting Recording
    │
    ▼
Transcribe (AI)
    │
    ▼
Summarize (AI)
    │
    ├──► Save to Notion
    ├──► Extract Action Items ──► Todoist
    └──► Send to Attendees (Email)
```

---

## 4. Finance Tracking

### Expense Logger

**Use Case:** Tự động log chi tiêu

```
Bank Email/SMS Trigger
    │
    ▼
Parse Transaction
    │
    ├──► Log to Google Sheets
    ├──► Categorize Expense
    └──► IF budget exceeded?
         │
         └──[Yes]──► Alert (Telegram/Email)
```

**Parse Transaction:**
```javascript
const email = $input.first().json;

// Extract from email body
const amount = email.body.match(/\$?([\d,]+\.?\d*)/)[1];
const merchant = email.body.match(/at ([\w\s]+)/)[1];
const date = email.body.match(/on ([\d-]+)/)[1];

// Categorize
const categories = {
  'Starbucks': 'coffee',
  'Amazon': 'shopping',
  'Uber': 'transport',
  'Netflix': 'entertainment'
};

const category = categories[merchant] || 'other';

return [{
  json: {
    date,
    merchant,
    amount: parseFloat(amount.replace(',', '')),
    category
  }
}];
```

### Subscription Tracker

```
Schedule (monthly)
    │
    ▼
Check Bank Statements
    │
    ▼
Identify Recurring Charges
    │
    ▼
Update Subscription List
    │
    ▼
IF new subscription?
    │
    └──[Yes]──► Notify + Ask to keep/cancel
```

---

## 5. Content Creation

### Blog Post Workflow

**Use Case:** Manage content creation pipeline

```
Idea Capture (any source)
    │
    ▼
Add to Content Pipeline (Notion/Airtable)
    │
    ▼
Weekly Review (Schedule)
    │
    ├──► Select Topics
    │    │
    │    ▼
    │ Research (AI web search)
    │    │
    │    ▼
    │ Generate Outline (AI)
    │    │
    │    ▼
    │ Write Draft
    │    │
    │    ▼
    │ Review & Edit
    │    │
    │    ▼
    │ Publish ──► Cross-post to platforms
    └──► Archive rejected ideas
```

### Social Media Scheduler

```
Content Calendar (Google Sheets)
    │
    ▼
Schedule (check every hour)
    │
    ▼
IF post due?
    │
    └──[Yes]──► Format for Platform
                │
                ├──► Post to Twitter
                ├──► Post to LinkedIn
                └──► Post to Facebook
                │
                ▼
                Log to Sheet
```

---

## 6. Learning & Research

### Daily Learning Digest

**Use Case:** Curate learning content

```
Schedule (daily 7 PM)
    │
    ├──► Fetch Reddit (r/programming, etc.)
    ├──► Fetch HackerNews top posts
    ├──► Fetch YouTube new videos (subscribed)
    └──► Fetch RSS feeds
         │
         ▼
    Filter by Keywords
         │
         ▼
    Summarize (AI)
         │
         ▼
    Send Evening Digest (Email)
```

### Research Assistant

**Use Case:** Deep dive vào topics

```
Topic Input (Webhook/Form)
    │
    ▼
Search Web (AI/APIs)
    │
    ▼
Fetch Top 10 Articles
    │
    ▼
Summarize Each (AI)
    │
    ▼
Generate Research Brief
    │
    ▼
Save to Notion + Send Email
```

---

## 7. Health & Wellness

### Habit Tracker

```
Schedule (daily 9 PM)
    │
    ▼
Check Habit Completion (from app/webhook)
    │
    ▼
Update Streaks
    │
    ▼
IF streak broken?
    │
    └──[Yes]──► Motivational Message
```

### Workout Logger

```
Telegram Bot / Webhook
    │
    ▼
Parse Workout Data
    │
    ▼
Log to Google Sheets
    │
    ▼
Calculate Progress
    │
    ▼
Weekly Summary (Email)
```

---

## 📱 Personal Automation Ideas

### Quick Commands

```
"/log [expense]"      → Log expense
"/task [description]" → Create task  
"/note [text]"        → Save note
"/remind [time] [what]" → Set reminder
```

### IFTTT-Style Automations

```
IF weather forecast says rain tomorrow
   THEN send Telegram notification tonight

IF new episode of favorite podcast released
   THEN download and send to phone

IF flight price drops below threshold
   THEN alert me

IF package delivery status changes
   THEN notify me
```

---

## 🔧 Personal Setup Tips

### Start Simple

```
Week 1: Email sorting
Week 2: Task management
Week 3: Expense tracking
Week 4: Content scheduling
```

### Use Templates

```
n8n.io/workflows có hàng trăm templates:
  ✓ Personal productivity
  ✓ Home automation
  ✓ Social media
  ✓ Finance tracking
```

### Keep It Private

```
Self-hosted n8n = Your data stays yours
  ✓ No third-party access
  ✓ Full control
  ✓ Custom integrations
  ✓ No usage limits
```

---

## ✅ Personal Automation Checklist

### Getting Started
- [ ] n8n installed (local or VPS)
- [ ] Core apps connected (email, calendar, tasks)
- [ ] First workflow created
- [ ] Webhooks tested

### Productivity
- [ ] Email auto-sorting working
- [ ] Task capture automated
- [ ] Daily briefing setup
- [ ] Expense tracking active

### Growth
- [ ] Content pipeline created
- [ ] Learning digest configured
- [ ] Social media scheduled
- [ ] Backups automated

### Optimization
- [ ] Review workflows monthly
- [ ] Remove unused automations
- [ ] Add new ones as needed
- [ ] Monitor execution logs

---

## 🚀 Next Steps

→ [Social Media Automation](23-social-media-automation.md)
→ [Knowledge Management](25-knowledge-management.md)
