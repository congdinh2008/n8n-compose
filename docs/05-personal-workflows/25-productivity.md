# Personal Productivity Workflows

## Overview

Các workflows cá nhân giúp:
- Tiết kiệm thời gian hàng ngày
- Tự động hóa repetitive tasks
- Tổ chức thông tin cá nhân
- Theo dõi thói quen và goals

---

## Workflow 1: Daily Personal Dashboard

### Use Case
Tạo daily briefing với weather, calendar, tasks, và news.

### Architecture
```
Schedule (7AM daily) → Get Weather → Get Calendar → Get Tasks → Get News → Compile → Send
```

### Implementation

#### Morning Briefing
```javascript
const weather = $('Get Weather').first().json;
const calendar = $('Get Calendar Events').all();
const tasks = $('Get Tasks').all();
const news = $('Get News').all();

const today = new Date();
const dateStr = today.toLocaleDateString('vi-VN', {
  weekday: 'long',
  year: 'numeric',
  month: 'long',
  day: 'numeric'
});

// Today's events
const eventsText = calendar.length > 0 
  ? calendar.map(e => `• ${e.json.title} at ${e.json.time}`).join('\n')
  : 'No events today';

// Pending tasks
const pendingTasks = tasks
  .filter(t => t.json.status === 'pending')
  .slice(0, 5);
  
const tasksText = pendingTasks.length > 0
  ? pendingTasks.map(t => `☐ ${t.json.title}`).join('\n')
  : 'All tasks complete!';

// Top news
const newsText = news.slice(0, 3)
  .map(n => `• ${n.json.title}`)
  .join('\n');

const briefing = `
📅 *${dateStr}*

🌤 *Weather*
${weather.temperature}°C, ${weather.condition}

📋 *Today's Schedule*
${eventsText}

✅ *Tasks*
${tasksText}

📰 *News*
${newsText}

Have a great day! 🚀
`;

return [{ json: { message: briefing } }];
```

---

## Workflow 2: Email Digest và Categorization

### Use Case
Tóm tắt emails quan trọng và categorize theo priority.

### Email Processing
```javascript
const emails = $('Get New Emails').all();

// Categorize
const categorized = emails.map(email => {
  const json = email.json;
  
  // Priority scoring
  let priority = 0;
  if (json.urgent_keywords?.some(k => json.subject.toLowerCase().includes(k))) {
    priority = 3; // High
  } else if (json.from_important_contact) {
    priority = 2; // Medium
  } else {
    priority = 1; // Low
  }
  
  return {
    json: {
      ...json,
      priority,
      category: categorizeEmail(json),
      action_required: needsAction(json)
    }
  };
});

// Filter out newsletters and spam
const important = categorized.filter(e => 
  e.json.priority >= 2 && !e.json.is_newsletter
);

return important;

function categorizeEmail(email) {
  const subject = email.subject.toLowerCase();
  if (subject.includes('invoice') || subject.includes('payment')) return 'finance';
  if (subject.includes('meeting') || subject.includes('calendar')) return 'calendar';
  if (subject.includes('task') || subject.includes('action')) return 'action';
  return 'general';
}

function needsAction(email) {
  return email.requires_response || 
         email.contains_question ||
         email.has_deadline;
}
```

---

## Workflow 3: Expense Tracking

### Use Case
Tự động track expenses từ emails, receipts, và bank transactions.

### Expense Processing
```
Receipt Photo → OCR Extract → Categorize → Log to Sheet → Budget Check
```

#### Receipt Processing
```javascript
const receipt = $input.first().json;

// Extract data (from OCR or manual entry)
const expense = {
  date: receipt.date || new Date().toISOString().split('T')[0],
  vendor: receipt.vendor,
  amount: parseFloat(receipt.total),
  currency: receipt.currency || 'VND',
  category: categorizeExpense(receipt),
  payment_method: receipt.payment_method,
  receipt_url: receipt.image_url
};

return [{ json: expense }];

function categorizeExpense(receipt) {
  const vendor = receipt.vendor.toLowerCase();
  if (vendor.includes('food') || vendor.includes('restaurant')) return 'food';
  if (vendor.includes('gas') || vendor.includes('fuel')) return 'transport';
  if (vendor.includes('hotel')) return 'accommodation';
  if (vendor.includes('office') || vendor.includes('supply')) return 'office';
  return 'other';
}
```

#### Budget Alert
```javascript
const expense = $input.first().json;
const budget = $('Get Monthly Budget').first().json;
const spent = $('Get Month Expenses').first().json.total;

const newTotal = spent + expense.amount;
const percentage = (newTotal / budget.amount) * 100;

let alert = null;
if (percentage >= 90) {
  alert = `⚠️ Budget warning: ${percentage.toFixed(0)}% used!`;
} else if (percentage >= 75) {
  alert = `📊 Budget alert: ${percentage.toFixed(0)}% used`;
}

return [{
  json: {
    ...expense,
    budget_total: newTotal,
    budget_percentage: percentage,
    alert
  }
}];
```

---

## Workflow 4: Reading List và Content Curation

### Use Case
Tự động collect articles, books, và resources từ nhiều sources.

### Content Collection
```
RSS Feeds ──┐
Twitter ────┤──→ Deduplicate → Enrich → Save to Notion → Tag
Newsletters┘
```

#### Article Processing
```javascript
const article = $input.first().json;

// Check if already saved
const existing = $('Get Saved Articles').all();
const isDuplicate = existing.some(a => 
  a.json.url === article.url
);

if (isDuplicate) {
  return []; // Skip duplicate
}

// Enrich with metadata
const enriched = {
  ...article,
  saved_at: new Date().toISOString(),
  tags: generateTags(article),
  estimated_read_time: Math.ceil(article.word_count / 200), // minutes
  priority: calculatePriority(article)
};

return [{ json: enriched }];

function generateTags(article) {
  const tags = [];
  const text = (article.title + ' ' + article.content).toLowerCase();
  
  if (text.includes('javascript') || text.includes('programming')) tags.push('tech');
  if (text.includes('business') || text.includes('startup')) tags.push('business');
  if (text.includes('design')) tags.push('design');
  if (text.includes('ai') || text.includes('machine learning')) tags.push('ai');
  
  return tags;
}
```

---

## Workflow 5: Habit Tracking

### Use Case
Track daily habits và send reminders.

### Habit Check
```javascript
const habits = $('Get Habits').all();
const today = new Date().toISOString().split('T')[0];
const completed = $('Get Today Completions').all();

const habitStatus = habits.map(habit => {
  const isCompleted = completed.some(c => 
    c.json.habit_id === habit.json.id && 
    c.json.date === today
  );
  
  return {
    habit: habit.json.name,
    completed: isCompleted,
    streak: habit.json.streak
  };
});

// Check if all completed
const allCompleted = habitStatus.every(h => h.completed);
const incomplete = habitStatus.filter(h => !h.completed);

// Send reminder if needed
if (!allCompleted && new Date().getHours() >= 20) {
  const reminder = `
📋 *Habit Reminder*

You still need to complete:
${incomplete.map(h => `• ${h.habit}`).join('\n')}

Current streaks:
${habitStatus.map(h => `• ${h.habit}: ${h.streak} days`).join('\n')}

Don't break the chain! 🔥
`;

  return [{ json: { reminder } }];
}

return []; // No reminder needed
```

---

## Workflow 6: Password Expiry Monitor

### Use Case
Nhắc nhở đổi passwords trước khi expiry.

### Monitor Setup
```javascript
const passwords = $('Get Password Entries').all();
const today = new Date();
const thirtyDays = new Date(today.getTime() + 30*24*60*60*1000);

const expiringSoon = passwords.filter(p => {
  const expiryDate = new Date(p.json.expiry_date);
  return expiryDate <= thirtyDays && expiryDate > today;
});

const alerts = expiringSoon.map(p => ({
  json: {
    service: p.json.service,
    url: p.json.url,
    expires: p.json.expiry_date,
    days_left: Math.floor(
      (new Date(p.json.expiry_date) - today) / (1000*60*60*24)
    )
  }
}));

return alerts;
```

---

## Workflow 7: Backup Automation

### Use Case
Tự động backup important files và data.

### Backup Process
```
Schedule (daily) → Collect Files → Compress → Upload to Cloud → Verify → Notify
```

#### File Collection
```javascript
// Get files to backup
const filesToBackup = [
  '/Users/congdinh/Documents',
  '/Users/congdinh/Projects',
  '/Users/congdinh/.config'
];

const backupName = `backup_${new Date().toISOString().split('T')[0]}`;

return [{
  json: {
    backup_name: backupName,
    files: filesToBackup,
    timestamp: new Date().toISOString()
  }
}];
```

---

## Workflow 8: Social Media Digest

### Use Case
Weekly summary của social media activity.

### Weekly Digest
```javascript
const twitter = $('Get Twitter Stats').first().json;
const linkedin = $('Get LinkedIn Stats').first().json;
const github = $('Get GitHub Stats').first().json;

const digest = `
📊 *Weekly Social Media Digest*

🐦 *Twitter*
• Followers: ${twitter.followers} (${twitter.followers_change > 0 ? '+' : ''}${twitter.followers_change})
• Tweets: ${twitter.tweets_count}
• Engagement rate: ${twitter.engagement_rate}%

💼 *LinkedIn*
• Connections: ${linkedin.connections} (${linkedin.connections_change > 0 ? '+' : ''}${linkedin.connections_change})
• Post impressions: ${linkedin.impressions}

💻 *GitHub*
• Stars: ${github.stars}
• Commits this week: ${github.commits}
• Active repos: ${github.active_repos}

Keep building! 🚀
`;

return [{ json: { digest } }];
```

---

## Workflow 9: Bill Payment Reminder

### Use Case
Nhắc nhở pay bills trước due date.

### Bill Tracking
```javascript
const bills = $('Get Upcoming Bills').all();
const today = new Date();
const sevenDays = new Date(today.getTime() + 7*24*60*60*1000);

const dueSoon = bills.filter(bill => {
  const dueDate = new Date(bill.json.due_date);
  return dueDate <= sevenDays && !bill.json.paid;
});

const reminders = dueSoon.map(bill => ({
  json: {
    service: bill.json.service,
    amount: bill.json.amount,
    due_date: bill.json.due_date,
    days_until_due: Math.floor(
      (new Date(bill.json.due_date) - today) / (1000*60*60*24)
    ),
    payment_url: bill.json.payment_url
  }
}));

return reminders;
```

---

## Best Practices

### ✅ Do
- Start with simple workflows
- Test thoroughly before automating
- Keep personal data secure
- Backup workflow configurations
- Review and optimize regularly
- Add error handling

### ❌ Don't
- Automate without understanding
- Store sensitive data insecurely
- Forget to monitor automation
- Skip manual checks initially
- Over-automate (keep some control)
- Ignore failed executions

---

## Tools thường dùng

### Personal Productivity
| Tool | Use Case |
|------|----------|
| Notion | Knowledge base |
| Todoist | Task management |
| Google Calendar | Scheduling |
| Trello | Project tracking |
| Notion/Obsidian | Notes |

### Finance
| Tool | Purpose |
|------|---------|
| Google Sheets | Expense tracking |
| Mint | Budget monitoring |
| Banking APIs | Transaction data |

### Communication
| Tool | Purpose |
|------|---------|
| Email | Notifications |
| Telegram | Quick alerts |
| Slack | Team updates |
| SMS | Urgent reminders |
