# Marketing Automation

## Overview

Tự động hóa marketing giúp:
- Tăng engagement với customers
- Personalize communications
- Track campaign performance
- Reduce manual marketing tasks

---

## Workflow 1: Multi-Channel Campaign Management

### Use Case
Quản lý campaigns across email, social media, và ads.

### Architecture
```
Campaign Created → Create Content → Schedule Posts → Track Performance → Report
```

### Implementation

#### Campaign Setup
```javascript
const campaign = $input.first().json;

const channels = [
  { name: 'email', enabled: campaign.email_enabled },
  { name: 'facebook', enabled: campaign.facebook_enabled },
  { name: 'linkedin', enabled: campaign.linkedin_enabled },
  { name: 'twitter', enabled: campaign.twitter_enabled }
].filter(ch => ch.enabled);

return channels.map(channel => ({
  json: {
    ...campaign,
    channel: channel.name,
    status: 'scheduled'
  }
}));
```

#### Email Campaign
```
Resource: Message
Operation: Send
To: {{ $json.target_audience }}
Subject: {{ $campaign.subject }}
Content: {{ $campaign.body }}
```

#### Social Media Posts
```javascript
// Platform-specific formatting
const post = $input.first().json;
const platform = post.channel;

let formattedPost;

switch(platform) {
  case 'twitter':
    formattedPost = {
      text: post.content.slice(0, 280),
      media: post.media?.slice(0, 4)
    };
    break;
  case 'linkedin':
    formattedPost = {
      text: post.content,
      media: post.media,
      hashtags: post.hashtags
    };
    break;
  case 'facebook':
    formattedPost = {
      message: post.content,
      link: post.link,
      media: post.media
    };
    break;
}

return [{ json: { ...post, formatted: formattedPost } }];
```

---

## Workflow 2: Lead Nurturing Drip Campaign

### Use Case
Tự động gửi emails dựa trên user behavior.

### Drip Sequence
```
Day 0:  Welcome email + Getting started guide
Day 3:  Case study relevant to their industry
Day 7:  Product demo invitation
Day 14: Customer testimonial
Day 21: Special offer / Discount
Day 30: Check-in + Next steps
```

#### Behavior Tracking
```javascript
const user = $input.first().json;
const activities = $('Get User Activities').all();

const openedEmails = activities.filter(a => 
  a.json.type === 'email_open'
).length;

const clickedLinks = activities.filter(a => 
  a.json.type === 'link_click'
).length;

const visitedPricing = activities.some(a => 
  a.json.type === 'page_visit' && 
  a.json.page === '/pricing'
);

// Calculate engagement score
const engagementScore = 
  (openedEmails * 10) + 
  (clickedLinks * 20) + 
  (visitedPricing ? 30 : 0);

// Determine next email
let nextEmail;
if (engagementScore >= 70) {
  nextEmail = 'demo_invitation';
} else if (engagementScore >= 40) {
  nextEmail = 'case_study';
} else {
  nextEmail = 'getting_started';
}

return [{
  json: {
    ...user,
    engagement_score: engagementScore,
    next_email: nextEmail,
    should_advance: engagementScore >= 30
  }
}];
```

---

## Workflow 3: Social Media Monitoring

### Use Case
Monitor mentions, track competitors, và identify opportunities.

### Monitoring Sources
- Brand mentions on social media
- Competitor mentions
- Industry keywords
- Product reviews

#### Track Mentions
```javascript
// Twitter mention
const mention = $input.first().json;

const sentiment = analyzeSentiment(mention.text);
const priority = calculatePriority(mention);

return [{
  json: {
    ...mention,
    sentiment: sentiment,
    priority: priority,
    needs_response: needsResponse(mention, sentiment)
  }
}];

function analyzeSentiment(text) {
  // Simple sentiment analysis
  const positive = ['great', 'love', 'excellent', 'amazing', 'best'];
  const negative = ['bad', 'hate', 'worst', 'terrible', 'awful'];
  
  let score = 0;
  positive.forEach(word => {
    if (text.toLowerCase().includes(word)) score++;
  });
  negative.forEach(word => {
    if (text.toLowerCase().includes(word)) score--;
  });
  
  return score > 0 ? 'positive' : score < 0 ? 'negative' : 'neutral';
}

function needsResponse(mention, sentiment) {
  return mention.mentions_brand || 
         sentiment === 'negative' ||
         mention.is_question;
}
```

---

## Workflow 4: Content Calendar Automation

### Use Case
Tự động lên lịch và publish content.

### Content Workflow
```
Idea → Draft → Review → Approved → Scheduled → Published
```

#### Content Approval
```javascript
const content = $input.first().json;

if (content.status === 'approved') {
  return [{
    json: {
      ...content,
      publish_date: calculatePublishDate(content),
      status: 'scheduled'
    }
  }];
} else {
  // Send back for revisions
  return [{
    json: {
      ...content,
      status: 'needs_revision',
      revision_comments: content.reviewer_comments
    }
  }];
}

function calculatePublishDate(content) {
  const now = new Date();
  const scheduleDays = content.priority === 'high' ? 1 : 3;
  return new Date(now.getTime() + scheduleDays * 24*60*60*1000)
    .toISOString();
}
```

---

## Workflow 5: Campaign Performance Reporting

### Use Case
Tự động aggregate và report campaign metrics.

### Report Generation
```javascript
// Weekly Performance Report
const campaigns = $('Get Active Campaigns').all();
const metrics = $('Get Campaign Metrics').all();

const report = {
  period: 'last_7_days',
  campaigns: campaigns.map(campaign => {
    const campaignMetrics = metrics.filter(m => 
      m.json.campaign_id === campaign.json.id
    );
    
    return {
      name: campaign.json.name,
      channel: campaign.json.channel,
      impressions: campaignMetrics.reduce((s, m) => s + m.json.impressions, 0),
      clicks: campaignMetrics.reduce((s, m) => s + m.json.clicks, 0),
      conversions: campaignMetrics.reduce((s, m) => s + m.json.conversions, 0),
      spend: campaignMetrics.reduce((s, m) => s + m.json.spend, 0),
      ctr: (campaignMetrics.reduce((s, m) => s + m.json.clicks, 0) / 
            campaignMetrics.reduce((s, m) => s + m.json.impressions, 0) * 100).toFixed(2),
      cpa: campaignMetrics.reduce((s, m) => s + m.json.spend, 0) / 
           campaignMetrics.reduce((s, m) => s + m.json.conversions, 0)
    };
  }),
  totals: {
    impressions: metrics.reduce((s, m) => s + m.json.impressions, 0),
    clicks: metrics.reduce((s, m) => s + m.json.clicks, 0),
    conversions: metrics.reduce((s, m) => s + m.json.conversions, 0),
    spend: metrics.reduce((s, m) => s + m.json.spend, 0)
  }
};

return [{ json: report }];
```

---

## Workflow 6: A/B Testing Automation

### Use Case
Tự động setup và analyze A/B tests.

### Test Setup
```javascript
const test = $input.first().json;

// Split audience
const audience = $('Get Target Audience').all();
const splitIndex = Math.floor(audience.length / 2);

const groupA = audience.slice(0, splitIndex);
const groupB = audience.slice(splitIndex);

return [
  ...groupA.map(item => ({
    json: { ...item.json, test_group: 'A', variant: test.variant_a }
  })),
  ...groupB.map(item => ({
    json: { ...item.json, test_group: 'B', variant: test.variant_b }
  }))
];
```

### Statistical Analysis
```javascript
// After test period
const results = $('Get Test Results').all();

const groupA = results.filter(r => r.json.test_group === 'A');
const groupB = results.filter(r => r.json.test_group === 'B');

const convA = groupA.filter(r => r.json.converted).length;
const convB = groupB.filter(r => r.json.converted).length;

const rateA = convA / groupA.length;
const rateB = convB / groupB.length;

// Simple significance check
const total = groupA.length + groupB.length;
const expectedA = convA + convB * (groupA.length / total);
const expectedB = convA + convB * (groupB.length / total);

const chiSquare = Math.pow(convA - expectedA, 2) / expectedA +
                  Math.pow(convB - expectedB, 2) / expectedB;

const isSignificant = chiSquare > 3.84; // p < 0.05

return [{
  json: {
    test_name: results[0].json.test_name,
    variant_a_rate: rateA,
    variant_b_rate: rateB,
    winner: rateA > rateB ? 'A' : 'B',
    significant: isSignificant,
    recommendation: isSignificant ? 
      `Implement variant ${rateA > rateB ? 'A' : 'B'}` : 
      'Continue test for more data'
  }
}];
```

---

## Integration Points

### Marketing Tools
| Tool | Use Case |
|------|----------|
| Mailchimp | Email campaigns |
| HubSpot | Marketing automation |
| Google Analytics | Track performance |
| Facebook Ads | Ad campaigns |
| LinkedIn | B2B marketing |
| Twitter | Social engagement |
| Hootsuite | Social scheduling |

### Analytics
| Tool | Purpose |
|------|---------|
| Google Analytics | Website traffic |
| Mixpanel | User behavior |
| Hotjar | Heatmaps |
| SEMrush | SEO performance |

---

## Best Practices

### ✅ Do
- Segment audiences properly
- Test one variable at a time
- Set clear KPIs before campaigns
- Monitor frequency to avoid ad fatigue
- Use UTM parameters for tracking
- A/B test subject lines

### ❌ Don't
- Send too many emails (respect unsubscribe)
- Ignore unsubscribe requests
- Mix personal and business accounts
- Forget to track ROI
- Skip mobile optimization
- Ignore negative feedback

---

## Key Metrics

| Metric | Formula | Target |
|--------|---------|--------|
| Open Rate | Opens / Delivered | > 20% |
| Click Rate | Clicks / Delivered | > 3% |
| Conversion Rate | Conversions / Clicks | > 5% |
| Unsubscribe Rate | Unsubscribes / Delivered | < 0.5% |
| CTR (Ads) | Clicks / Impressions | > 1% |
| CPA | Spend / Conversions | < Target |
| ROAS | Revenue / Spend | > 3x |
