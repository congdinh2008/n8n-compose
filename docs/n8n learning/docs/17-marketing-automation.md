# 📧 Marketing Automation

## 1. Email Campaign Automation

### Welcome Series

**Use Case:** Tự động gửi email sequence khi user signup

```
New User Signup
    │
    ▼
Wait (immediate)
    │
    ▼
Send Welcome Email (#1)
    │
    ▼
Wait (2 days)
    │
    ▼
Send Getting Started (#2)
    │
    ▼
Wait (3 days)
    │
    ▼
IF opened previous email?
    │
    ├──[Yes]──► Send Advanced Tips (#3)
    │
    └──[No]───► Resend Getting Started (#2b)
```

**Implementation:**

**Email #1: Welcome**
```
Trigger: Webhook (signup)
    │
    ▼
Gmail/SendGrid Node:
  To: {{ $json.email }}
  Subject: Welcome to [Product]! 👋
  
  Body:
    Hi {{ $json.name }},
    
    Welcome aboard! Here's how to get started:
    
    1. Complete your profile
    2. Connect your first integration
    3. Create your first workflow
    
    Need help? Reply to this email!
    
    Best,
    The Team
```

**Check Email Open:**
```javascript
// Track opens via webhook
const userId = $json.userId;
const eventType = $json.event; // 'open', 'click'

// Update user record
await updateUser(userId, {
  last_email_opened: new Date().toISOString(),
  email_sequence_step: 2
});

return [{ json: { userId, proceed: true } }];
```

---

### Re-engagement Campaign

**Use Case:** Win back inactive users

```
Schedule (weekly)
    │
    ▼
Query Inactive Users (last 30 days)
    │
    ▼
Split Into Batches (100)
    │
    ▼
Send Re-engagement Email
    │
    ▼
Wait (7 days)
    │
    ▼
IF opened?
    │
    ├──[Yes]──► Move to Active Segment
    │
    └──[No]───► Send Final Attempt
                │
                ▼
                Wait (7 days)
                │
                ▼
                IF opened?
                │
                ├──[Yes]──► Move to Active Segment
                │
                └──[No]───► Mark as Churned
```

---

## 2. Social Media Automation

### Cross-Platform Posting

**Use Case:** Post content đến multiple platforms

```
New Blog Post (RSS/Trigger)
    │
    ▼
Extract Content
    │
    ├──► Format for Twitter ──► Post to Twitter
    │
    ├──► Format for LinkedIn ──► Post to LinkedIn
    │
    ├──► Format for Facebook ──► Post to Facebook
    │
    └──► Format for Instagram ──► Create + Post
```

**Format for Twitter:**
```javascript
const blog = $input.first().json;

// Extract key points
const content = blog.content
  .split('\n')
  .filter(p => p.length > 50)
  .slice(0, 3);

const tweet = `📝 New Blog Post!\n\n${blog.title}\n\n${content[0].substring(0, 200)}...\n\nRead more: ${blog.url}`;

return [{ json: { content: tweet, url: blog.url } }];
```

---

### Content Calendar Scheduler

```
Google Sheets (Content Calendar)
    │
    ▼
Filter Today's Posts
    │
    ▼
IF scheduled_time reached?
    │
    ├──[Yes]──► Format Post
    │           │
    │           ▼
    │       Post to Platform
    │           │
    │           ▼
    │       Update Sheet (posted)
    │
    └──[No]───► Wait Until scheduled_time
```

---

## 3. Lead Nurturing

### Multi-Channel Nurture

```
New Lead (CRM Trigger)
    │
    ▼
Add to Email Sequence
    │
    ▼
Add to LinkedIn Audience (Custom Audience)
    │
    ▼
Send Retargeting Ads (if website visit)
    │
    ▼
Schedule Follow-up (if no response in 7 days)
    │
    ▼
Score Engagement
    │
    ├──[High]──► Notify Sales
    │
    └──[Low]───► Continue Nurture
```

---

## 4. Analytics & Reporting

### Campaign Performance Dashboard

```
Schedule (daily 9 AM)
    │
    ├──► Fetch Email Stats (SendGrid/Mailchimp)
    ├──► Fetch Social Stats (Twitter/LinkedIn API)
    ├──► Fetch Ad Stats (Facebook/Google Ads)
    └──► Fetch Website Stats (Google Analytics)
         │
         ▼
    Aggregate Data
         │
         ▼
    Generate Report (Google Sheets)
         │
         ▼
    Send to Team (Slack/Email)
```

**Aggregate Data:**
```javascript
const email = $node["Email Stats"].all()[0].json;
const social = $node["Social Stats"].all()[0].json;
const ads = $node["Ad Stats"].all()[0].json;

const report = {
  date: $now.format('yyyy-MM-dd'),
  email: {
    sent: email.sent,
    opens: email.opens,
    clicks: email.clicks,
    open_rate: (email.opens / email.sent * 100).toFixed(2) + '%'
  },
  social: {
    posts: social.posts_count,
    engagements: social.engagements,
    followers_gained: social.new_followers
  },
  ads: {
    spend: ads.spend,
    impressions: ads.impressions,
    clicks: ads.clicks,
    ctr: (ads.clicks / ads.impressions * 100).toFixed(2) + '%'
  }
};

return [{ json: report }];
```

---

## 5. Event Marketing

### Webinar Automation

```
New Registration (Webhook)
    │
    ├──► Add to Attendee List (Google Sheets)
    ├──► Send Confirmation Email
    ├──► Add Calendar Invite
    └──► Send Reminder Sequence
         │
         ├── 7 days before
         ├── 1 day before
         └── 1 hour before
```

### Post-Event Follow-up

```
Webinar Ended (Trigger)
    │
    ▼
Segment Attendees
    ├── Attended full
    ├── Attended partial
    └── Registered but no-show
    │
    ▼
Send Targeted Follow-up
    ├── Full: Next steps + resources
    ├── Partial: Recording + key points
    └── No-show: Recording available
```

---

## 📊 Marketing Metrics

```
Email Marketing:
  ✓ Open rate
  ✓ Click-through rate
  ✓ Unsubscribe rate
  ✓ Bounce rate
  ✓ Conversion rate

Social Media:
  ✓ Engagement rate
  ✓ Follower growth
  ✓ Reach/impressions
  ✓ Click rate

Campaigns:
  ✓ Cost per lead
  ✓ Lead velocity
  ✓ Pipeline generated
  ✓ ROI by channel
```

---

## ✅ Marketing Automation Checklist

### Setup
- [ ] Email service connected
- [ ] Social accounts connected
- [ ] CRM integration active
- [ ] Analytics tracking enabled
- [ ] Segments defined

### Workflows
- [ ] Welcome series created
- [ ] Nurture sequences built
- [ ] Re-engagement campaign ready
- [ ] Social posting scheduled
- [ ] Reports automated

### Compliance
- [ ] GDPR consent tracked
- [ ] Unsubscribe links working
- [ ] Data retention policy set
- [ ] Preference center available
- [ ] Double opt-in enabled

---

## 🚀 Next Steps

→ [HR Management](18-hr-employee-management.md)
→ [Finance & Invoicing](19-finance-invoicing.md)
