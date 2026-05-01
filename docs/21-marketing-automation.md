# 21. Marketing Automation với N8N

## 📋 Mục lục
- [Tổng quan](#tổng-quan)
- [Social Media Automation](#social-media-automation)
- [Email Campaign Automation](#email-campaign-automation)
- [Content Distribution](#content-distribution)
- [Lead Generation](#lead-generation)
- [Analytics & Reporting](#analytics--reporting)
- [Best Practices](#best-practices)

---

## Tổng quan

Marketing automation là một trong những use cases phổ biến nhất của N8N, giúp tiết kiệm thời gian và tăng hiệu quả campaigns.

### Areas to Automate

| Area | Time Saved | Impact |
|------|------------|--------|
| **Social Media** | 5-10 hrs/week | High |
| **Email Campaigns** | 3-5 hrs/week | High |
| **Content Distribution** | 2-4 hrs/week | Medium |
| **Lead Generation** | 4-6 hrs/week | High |
| **Analytics** | 3-5 hrs/week | Medium |
| **Reporting** | 2-3 hrs/week | Medium |

---

## Social Media Automation

### Use Case 1: Cross-Platform Posting

Đăng nội dung lên nhiều platforms cùng lúc.

### Workflow

```
[New Content from CMS/Sheet]
       │
       ▼
[Format for Each Platform]
       │
    ┌──┴──┐
    ▼     ▼     ▼     ▼
[Twitter] [LinkedIn] [Facebook] [Instagram]
```

### Implementation

**Step 1: Content Source**

```json
{
  "name": "Google Sheets - New Content",
  "type": "n8n-nodes-base.googleSheetsTrigger",
  "parameters": {
    "sheetId": "{{ $env.SHEET_ID }}",
    "event": "rowAdded"
  }
}
```

**Sheet Structure:**

| Date | Platform | Content | Image URL | Status |
|------|----------|---------|-----------|--------|
| 2024-01-15 | All | Check out our new feature! | https://... | Scheduled |

**Step 2: Format for Twitter**

```javascript
const content = $input.first().json;

// Twitter: Max 280 chars
const tweet = {
  text: content.content.slice(0, 280),
  media: content.image_url ? [content.image_url] : [],
  scheduled_at: content.date + 'T09:00:00Z'
};

// Add hashtags if not present
if (!tweet.text.includes('#')) {
  tweet.text += ' #TechNews #Innovation';
}

return { json: tweet };
```

**Step 3: Format for LinkedIn**

```javascript
const content = $input.first().json;

// LinkedIn: Longer posts OK
const linkedinPost = {
  text: content.content,
  image: content.image_url,
  scheduled_at: content.date + 'T10:00:00Z'
};

// Professional tone
if (!linkedinPost.text.includes('\n\n')) {
  // Add line breaks for readability
  linkedinPost.text = linkedinPost.text
    .replace(/\. /g, '.\n\n');
}

return { json: linkedinPost };
```

**Step 4: Post to Platforms**

```javascript
// Twitter/X API
const tweet = await fetch('https://api.twitter.com/2/tweets', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${process.env.TWITTER_TOKEN}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ text: $json.text })
});

return { json: { twitter_id: tweet.data.id, status: 'posted' } };
```

### Use Case 2: Content Calendar Automation

```
[Schedule: Daily 8AM]
       │
       ▼
[Check Today's Posts]
       │
       ▼
[Post to Scheduled Platforms]
       │
       ▼
[Log Results]
```

---

## Email Campaign Automation

### Use Case 1: Drip Campaign

Automated email sequence based on user actions.

### Workflow

```
[User Subscribes]
       │
       ▼
[Send Welcome Email]
       │
       ▼
[Wait 2 Days]
       │
       ▼
[Check if Opened Welcome]
       │
    ┌──┴──┐
    ▼     ▼
[Yes]  [No]
  │      │
  ▼      ▼
[Send Email 2] [Resend Welcome]
       │
       ▼
[Wait 3 Days]
       │
       ▼
[Check Engagement]
       │
    ┌──┴──┐
    ▼     ▼
[Active] [Inactive]
  │        │
  ▼        ▼
[Send Email 3] [Re-engagement]
```

### Implementation

**Welcome Email:**

```javascript
const user = $input.first().json;

const email = {
  to: user.email,
  subject: `Welcome ${user.name}! 🎉`,
  html: `
    <h1>Welcome to our community!</h1>
    <p>Hi ${user.name},</p>
    <p>We're excited to have you on board.</p>
    <p>Here's what to expect:</p>
    <ul>
      <li>Weekly tips and insights</li>
      <li>Exclusive content</li>
      <li>Early access to new features</li>
    </ul>
    <p>Let's get started!</p>
  `
};

return { json: email };
```

**Engagement Tracking:**

```javascript
const user = $input.first().json;

// Check email opens and clicks
const opens = await $('Database').execute('query', {
  query: `SELECT COUNT(*) FROM email_opens 
          WHERE user_id = '${user.id}' 
          AND created_at > NOW() - INTERVAL 7 DAYS`
});

const clicks = await $('Database').execute('query', {
  query: `SELECT COUNT(*) FROM email_clicks 
          WHERE user_id = '${user.id}' 
          AND created_at > NOW() - INTERVAL 7 DAYS`
});

const isEngaged = opens.count > 0 || clicks.count > 0;

return {
  json: {
    ...user,
    engagement: {
      opens: opens.count,
      clicks: clicks.count,
      is_engaged: isEngaged
    }
  }
};
```

### Use Case 2: Newsletter Automation

```
[Schedule: Weekly Monday 9AM]
       │
       ▼
[Fetch Blog Posts from Week]
       │
       ▼
[Fetch Top Resources]
       │
       ▼
[Compile Newsletter]
       │
       ▼
[Send to Mailchimp/Substack]
```

---

## Content Distribution

### Use Case: Auto-distribute New Content

Phân phối nội dung mới đến nhiều channels.

### Workflow

```
[New Blog Post Published]
       │
       ▼
[Extract Key Points]
       │
    ┌──┴──┐
    ▼     ▼
[Create Social Posts] [Update RSS]
    │                      │
    ▼                      ▼
[Schedule Posts]     [Notify Subscribers]
    │
    ▼
[Create Newsletter Section]
```

### Implementation

**Content Processing:**

```javascript
const blogPost = $input.first().json;

// Extract key points (simple NLP)
const sentences = blogPost.content.match(/[^.!?]+[.!?]+/g);
const keyPoints = sentences
  .filter(s => s.length > 50 && s.length < 200)
  .slice(0, 3);

// Generate social posts
const socialPosts = {
  twitter: `${blogPost.title.slice(0, 250)}\n\nRead more: ${blogPost.url}`,
  linkedin: `${blogPost.title}\n\n${keyPoints.join('\n\n')}\n\nRead the full article: ${blogPost.url}`,
  facebook: `Check out our latest blog post!\n\n${blogPost.title}\n${blogPost.excerpt}\n\n${blogPost.url}`
};

return { json: { ...blogPost, social_posts: socialPosts } };
```

---

## Lead Generation

### Use Case 1: Lead Magnet Delivery

Tự động gửi tài liệu khi user subscribe.

### Workflow

```
[User Submits Form]
       │
       ▼
[Add to Email List]
       │
       ▼
[Send Lead Magnet]
       │
       ▼
[Schedule Follow-up]
```

### Use Case 2: Webinar Registration

```
[User Registers for Webinar]
       │
       ▼
[Confirmation Email]
       │
       ▼
[Add to CRM]
       │
       ▼
[Remind 24h Before]
       │
       ▼
[Remind 1h Before]
       │
       ▼
[After Webinar: Follow-up Email]
```

---

## Analytics & Reporting

### Use Case 1: Daily Marketing Dashboard

Tổng hợp metrics từ nhiều sources.

### Workflow

```
[Schedule: Daily 8AM]
       │
       ▼
[Fetch Google Analytics]
       │
       ▼
[Fetch Social Media Stats]
       │
       ▼
[Fetch Email Campaign Stats]
       │
       ▼
[Fetch Ad Performance]
       │
       ▼
[Compile Report]
       │
       ▼
[Send to Slack/Email]
```

### Report Template

```javascript
// Compile daily report
const ga = $('Google Analytics').item.json;
const social = $('Social').item.json;
const email = $('Email').item.json;
const ads = $('Ads').item.json;

const report = {
  date: $now.toFormat('yyyy-MM-dd'),
  website: {
    sessions: ga.sessions,
    pageviews: ga.pageviews,
    bounce_rate: ga.bounce_rate,
    conversions: ga.conversions
  },
  social: {
    followers: social.total_followers,
    engagement_rate: social.engagement_rate,
    posts_published: social.posts_count
  },
  email: {
    subscribers: email.subscriber_count,
    open_rate: email.open_rate,
    click_rate: email.click_rate,
    new_subscribers: email.new_count
  },
  ads: {
    spend: ads.spend,
    impressions: ads.impressions,
    clicks: ads.clicks,
    conversions: ads.conversions,
    roas: ads.roas
  }
};

return { json: report };
```

### Slack Report Format

```
📊 Marketing Daily Report - {{ $json.date }}

🌐 Website
• Sessions: {{ $json.website.sessions }}
• Pageviews: {{ $json.website.pageviews }}
• Conversions: {{ $json.website.conversions }}

📱 Social
• Followers: {{ $json.social.followers }}
• Engagement: {{ $json.social.engagement_rate }}%

📧 Email
• Subscribers: {{ $json.email.subscribers }}
• Open Rate: {{ $json.email.open_rate }}%

💰 Ads
• Spend: ${{ $json.ads.spend }}
• ROAS: {{ $json.ads.roas }}x
```

---

## Best Practices

### Social Media

1. ✅ Schedule posts for optimal times
2. ✅ Format appropriately per platform
3. ✅ Include visuals when possible
4. ✅ Monitor comments and mentions
5. ✅ Track engagement metrics

### Email Campaigns

1. ✅ Segment your audience
2. ✅ A/B test subject lines
3. ✅ Personalize when possible
4. ✅ Clean list regularly
5. ✅ Monitor deliverability

### Analytics

1. ✅ Track consistent metrics
2. ✅ Compare period-over-period
3. ✅ Focus on actionable metrics
4. ✅ Share with team regularly
5. ✅ Automate where possible

---

**[← Quay lại mục lục](README.md)**
