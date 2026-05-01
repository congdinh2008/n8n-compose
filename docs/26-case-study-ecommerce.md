# 📊 Case Study: E-commerce

## Bối cảnh

**Company:** TechStore.vn - Online electronics retailer
**Team:** 15 people (sales, support, marketing)
**Stack:** Shopify, Gmail, Slack, HubSpot, Google Sheets
**Problem:** Manual processes causing delays and errors

---

## Problems Identified

### 1. Order Processing
```
Before Automation:
  ✗ Manual order entry (15 min/order)
  ✗ Delayed customer notifications (2-4 hours)
  ✗ Inventory not synced
  ✗ Shipping updates manual
  
After Automation:
  ✓ Instant order processing (30 sec)
  ✓ Immediate customer confirmation
  ✓ Real-time inventory sync
  ✓ Auto shipping tracking
```

### 2. Customer Support
```
Before:
  ✗ Emails lost in inbox
  ✗ No priority routing
  ✗ Manual ticket creation
  ✗ Response time: 6+ hours
  
After:
  ✓ Auto email → ticket creation
  ✓ Priority classification
  ✓ SLA monitoring
  ✓ Response time: < 1 hour
```

### 3. Marketing Campaigns
```
Before:
  ✗ Manual campaign tracking
  ✗ Reports created weekly (4 hours)
  ✗ No customer segmentation
  ✗ Generic email blasts
  
After:
  ✓ Real-time campaign metrics
  ✓ Daily auto-reports (5 min)
  ✓ Dynamic segmentation
  ✓ Targeted email sequences
```

---

## Workflows Implemented

### 1. Order Fulfillment Pipeline

```
Shopify Trigger (New Order)
    │
    ▼
Validate Order
    │
    ├──► Check inventory (Google Sheets)
    │    │
    │    ├──[In Stock]──► Reserve items
    │    │                 │
    │    │                 ▼
    │    │             Send confirmation email
    │    │                 │
    │    │                 ▼
    │    │             Notify warehouse (Slack)
    │    │                 │
    │    │                 ▼
    │    │             Create shipping label
    │    │                 │
    │    │                 ▼
    │    │             Send tracking info to customer
    │    │
    │    └──[Out of Stock]──► Notify customer
    │                          │
    │                          ▼
    │                      Suggest alternatives
    │
    └──► Update CRM (HubSpot)
         │
         ▼
         Add to customer purchase history
```

**Metrics:**
```
Processing time: 15 min → 30 sec
Error rate: 8% → 0.5%
Customer satisfaction: 3.8 → 4.6/5
```

### 2. Customer Support Automation

```
Gmail Trigger (Support email)
    │
    ▼
Parse Email (AI)
    │
    ├──[Refund Request]──► Create refund ticket
    │                       │
    │                       ▼
    │                   Auto-approve if < $50
    │
    ├──[Product Question]──► Search knowledge base
    │                         │
    │                         ▼
    │                     Generate response (AI)
    │
    ├──[Technical Issue]──► Create high-priority ticket
    │                        │
    │                        ▼
    │                    Assign to tech team
    │
    └──[General]─────────► Create standard ticket
                           │
                           ▼
                       Auto-respond with FAQ
```

**Metrics:**
```
First response time: 6 hours → 45 minutes
Resolution time: 24 hours → 8 hours
Tickets handled automatically: 40%
Team capacity: +60%
```

### 3. Customer Re-engagement

```
Schedule (weekly)
    │
    ▼
Segment Customers:
  ├── Active (purchased < 30 days)
  ├── At-risk (30-90 days)
  └── Churned (> 90 days)
       │
       ├──[At-risk]──► Send personalized offer
       │               │
       │               ▼
       │           Track engagement
       │
       └──[Churned]──► Win-back campaign
                       │
                       ▼
                   Special discount
                       │
                       ▼
                   IF opens email → Move to At-risk
```

**Results:**
```
Re-engagement rate: 15%
Revenue from win-back: $12K/month
Customer retention: +25%
```

---

## ROI Analysis

### Before vs After

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Order processing | 15 min | 30 sec | 97% faster |
| Support response | 6 hours | 45 min | 87% faster |
| Report generation | 4 hours/week | 5 min/day | 95% faster |
| Error rate | 8% | 0.5% | 94% reduction |
| Marketing ROI | 2.1x | 3.8x | 81% increase |

### Time Saved

```
Order processing: 2 hours/day
Support: 3 hours/day  
Reports: 3.5 hours/week
Marketing: 5 hours/week

Total: ~15 hours/week = $750/week (at $50/hr)
Annual savings: $39,000
```

### Costs

```
n8n self-hosted: Free (existing server)
Server costs: $50/month
Setup time: 40 hours (one-time)
Maintenance: 2 hours/week

Total annual cost: ~$1,600
Net annual savings: $37,400
ROI: 2,337%
```

---

## Key Learnings

### ✅ What Worked

1. **Start with high-impact workflows**
   - Order processing had immediate ROI
   - Quick wins built team confidence

2. **Use AI for classification**
   - Email parsing accuracy: 95%
   - Reduced manual categorization

3. **Implement monitoring early**
   - Caught issues before they scaled
   - Built trust with stakeholders

### ⚠️ Challenges

1. **Data quality issues**
   - Inconsistent product names
   - Solution: Data validation workflow

2. **API rate limits**
   - Shopify: 2 calls/sec
   - Solution: Queue with rate limiting

3. **Team adoption**
   - Initial resistance to automation
   - Solution: Training + gradual rollout

---

## Architecture

```
┌───────────────────────────────────────┐
│           n8n Instance                │
│         (DigitalOcean $50/mo)         │
├───────────────────────────────────────┤
│                                       │
│  ┌─────────────┐  ┌──────────────┐   │
│  │ Order Flow  │  │ Support Flow │   │
│  └─────────────┘  └──────────────┘   │
│  ┌─────────────┐  ┌──────────────┐   │
│  │MarketingFlow│  │  Report Flow │   │
│  └─────────────┘  └──────────────┘   │
│                                       │
└───┬────────┬────────┬────────┬────────┘
    │        │        │        │
    ▼        ▼        ▼        ▼
 Shopify  Gmail   HubSpot  Slack
```

---

## Recommendations

### For Similar Businesses

1. **Start simple**
   - One workflow at a time
   - Measure impact before scaling

2. **Focus on customer-facing processes**
   - Immediate impact on satisfaction
   - Easy to justify investment

3. **Document everything**
   - Workflow diagrams
   - Owner assignments
   - Recovery procedures

4. **Plan for growth**
   - Queue mode for scale
   - Database backup strategy
   - Monitoring from day one

---

## 🚀 Next Steps

→ [SaaS Company](27-case-study-saas.md)
→ [Agency](28-case-study-agency.md)
