# Social Media Automation

## Overview

Tự động hóa social media giúp:
- Tiết kiệm thời gian posting
- Tăng consistency
- Monitor brand mentions
- Analyze performance

---

## Workflow 1: Cross-Platform Posting

### Use Case
Post một lần, publish lên multiple platforms.

### Architecture
```
Create Content → Format for Platform → Schedule → 
Post to Twitter → Post to LinkedIn → Post to Facebook
```

### Implementation

#### Content Formatting
```javascript
const content = $input.first().json;

// Platform-specific formatting
const platforms = [
  {
    name: 'twitter',
    text: content.text.slice(0, 280),
    media: content.media?.slice(0, 4),
    hashtags: content.hashtags
  },
  {
    name: 'linkedin',
    text: content.text,
    media: content.media,
    hashtags: content.hashtags
  },
  {
    name: 'facebook',
    text: content.text,
    media: content.media,
    link: content.link
  }
];

return platforms.map(platform => ({
  json: {
    ...content,
    ...platform,
    scheduled_time: content.publish_time
  }
}));
```

#### Post to Twitter
```javascript
const tweet = $input.first().json;

// Twitter API via HTTP Request
return [{
  json: {
    url: 'https://api.twitter.com/2/tweets',
    method: 'POST',
    headers: {
      'Authorization': 'Bearer ' + process.env.TWITTER_TOKEN
    },
    body: {
      text: tweet.text + (tweet.hashtags ? '\n\n' + tweet.hashtags : '')
    }
  }
}];
```

---

## Workflow 2: Content Calendar Automation

### Use Case
Tự động lên lịch content theo calendar.

### Content Queue
```
Ideas → Create Content → Review → Approve → Schedule → Publish
```

#### Schedule Management
```javascript
const calendar = $('Get Content Calendar').all();
const now = new Date();

// Get items due to publish
const toPublish = calendar.filter(item => {
  const publishTime = new Date(item.json.publish_time);
  return publishTime <= now && item.json.status === 'approved';
});

// Update status
return toPublish.map(item => ({
  json: {
    ...item.json,
    status: 'publishing',
    actual_publish_time: now.toISOString()
  }
}));
```

---

## Workflow 3: Social Media Monitoring

### Use Case
Monitor mentions, track sentiment, identify opportunities.

### Monitoring Flow
```
Track Keywords → Filter Mentions → Analyze Sentiment → 
Prioritize → Notify Team → Log
```

#### Sentiment Analysis
```javascript
const mention = $input.first().json;

// Simple sentiment analysis
const positive = ['great', 'love', 'excellent', 'amazing', 'best', 'awesome'];
const negative = ['bad', 'hate', 'worst', 'terrible', 'awful', 'disappointed'];

let score = 0;
positive.forEach(word => {
  if (mention.text.toLowerCase().includes(word)) score++;
});
negative.forEach(word => {
  if (mention.text.toLowerCase().includes(word)) score--;
});

const sentiment = score > 0 ? 'positive' : 
                  score < 0 ? 'negative' : 'neutral';

return [{
  json: {
    ...mention,
    sentiment,
    sentiment_score: score,
    priority: sentiment === 'negative' ? 'high' : 
              sentiment === 'positive' ? 'low' : 'medium',
    needs_response: sentiment === 'negative' || 
                    mention.text.includes('?')
  }
}];
```

---

## Workflow 4: Analytics Reporting

### Use Case
Weekly/monthly social media performance reports.

### Report Generation
```javascript
const twitter = $('Get Twitter Analytics').first().json;
const linkedin = $('Get LinkedIn Analytics').first().json;
const facebook = $('Get Facebook Analytics').first().json;

const report = {
  period: 'last_7_days',
  twitter: {
    followers: twitter.followers,
    tweets: twitter.tweets_count,
    impressions: twitter.impressions,
    engagement_rate: twitter.engagement_rate
  },
  linkedin: {
    followers: linkedin.followers,
    posts: linkedin.posts_count,
    impressions: linkedin.impressions,
    engagement_rate: linkedin.engagement_rate
  },
  facebook: {
    followers: facebook.followers,
    posts: facebook.posts_count,
    impressions: facebook.impressions,
    engagement_rate: facebook.engagement_rate
  },
  totals: {
    followers: twitter.followers + linkedin.followers + facebook.followers,
    posts: twitter.tweets_count + linkedin.posts_count + facebook.posts_count,
    impressions: twitter.impressions + linkedin.impressions + facebook.impressions
  }
};

return [{ json: report }];
```

---

## Workflow 5: Influencer Outreach

### Use Case
Identify and engage with potential influencers.

### Outreach Flow
```
Find Influencers → Score Relevance → Check Engagement → 
Send Outreach → Track Responses → Schedule Follow-up
```

#### Influencer Scoring
```javascript
const influencer = $input.first().json;

const score = 
  (influencer.followers < 100000 ? 30 : 
   influencer.followers < 500000 ? 20 : 10) +
  (influencer.engagement_rate > 3 ? 40 : 
   influencer.engagement_rate > 1 ? 20 : 10) +
  (influencer.niche_relevance > 0.7 ? 30 : 
   influencer.niche_relevance > 0.5 ? 15 : 0);

return [{
  json: {
    ...influencer,
    score,
    tier: score >= 70 ? 'A' : score >= 50 ? 'B' : 'C',
    should_contact: score >= 50 && !influencer.already_contacted
  }
}];
```

---

## Workflow 6: Competitor Analysis

### Use Case
Track competitor social media activity.

### Monitoring
```javascript
const competitors = $('Get Competitor Activity').all();

const analysis = competitors.map(comp => {
  const activity = comp.json;
  
  return {
    competitor: activity.name,
    posts_this_week: activity.posts_count,
    avg_engagement: activity.avg_engagement,
    top_post: activity.top_post,
    growth: activity.follower_growth
  };
});

return [{ json: { analysis, date: new Date().toISOString() } }];
```

---

## Best Practices

### ✅ Do
- Space out posts throughout the day
- Use platform-specific formatting
- Monitor engagement metrics
- Respond to comments quickly
- Test posting times
- Track ROI

### ❌ Don't
- Post too frequently (spam)
- Ignore negative comments
- Post same content everywhere
- Forget to engage back
- Buy followers
- Ignore analytics
