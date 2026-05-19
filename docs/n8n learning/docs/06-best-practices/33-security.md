# Security Best Practices

## 1. Infrastructure Security

### Network Security

**Firewall Rules:**
```bash
# Allow only necessary ports
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw enable
```

**Docker Network:**
```yaml
networks:
  n8n-internal:
    internal: true  # No external access
  n8n-public:
    driver: bridge
```

### SSL/TLS Configuration

**Nginx:**
```nginx
server {
    listen 443 ssl http2;
    server_name n8n.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/n8n.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/n8n.yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 2. Authentication & Authorization

### User Management

**Best practices:**
- Strong passwords (12+ chars)
- Enable 2FA if available
- Regular password rotation
- Remove inactive users
- Role-based access control

### API Security

**API Key Management:**
```bash
# Generate strong API key
openssl rand -base64 32

# Rotate regularly
N8N_API_KEY=$(openssl rand -base64 32)
```

**Secure Headers:**
```
X-N8N-API-KEY: your_secure_key
```

### Webhook Security

**Signature Verification:**
```javascript
const crypto = require('crypto');

function verifyWebhook(payload, signature, secret) {
  const expected = 'sha256=' + crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expected)
  );
}
```

---

## 3. Data Protection

### Encryption

**At Rest:**
```bash
# Database encryption
DB_POSTGRESDB_SSL_MODE=require
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=true
```

**In Transit:**
```bash
# Force HTTPS
N8N_PROTOCOL=https
N8N_SECURE_COOKIE=true
```

### Sensitive Data

**Masking in Logs:**
```javascript
function maskSensitiveData(data) {
  const masked = { ...data };
  
  if (masked.email) {
    masked.email = masked.email.replace(/(.{2}).*(@.*)/, '$1***$2');
  }
  if (masked.phone) {
    masked.phone = masked.phone.replace(/(\d{3})\d{4}(\d{3})/, '$1****$2');
  }
  if (masked.api_key) {
    masked.api_key = masked.api_key.substring(0, 4) + '****';
  }
  
  return masked;
}
```

**Never Log:**
- Passwords
- API keys
- Tokens
- Credit card numbers
- Personal identification numbers

---

## 4. Credential Security

### Storage

**Best practices:**
- Use n8n credential manager
- Strong encryption key (32+ chars)
- Regular rotation
- Separate environments

### Rotation Schedule

| Credential Type | Rotation Period |
|----------------|-----------------|
| API Keys | 90 days |
| Database passwords | 60 days |
| OAuth tokens | When suspicious |
| Webhook secrets | 180 days |

### Access Control

**Principle of least privilege:**
```
Database user:
✅ SELECT on specific tables
❌ DROP, DELETE permissions

API token:
✅ Read-only access
❌ Admin permissions
```

---

## 5. Environment Security

### Environment Variables

**Secure storage:**
```bash
# Use .env file (not in git)
echo ".env" >> .gitignore

# Use secrets manager in production
AWS Secrets Manager
HashiCorp Vault
Docker Secrets
```

**Production .env:**
```bash
# Strong encryption key
N8N_ENCRYPTION_KEY=$(openssl rand -base64 48)

# Secure settings
N8N_SECURE_COOKIE=true
N8N_BLOCK_ENV_ACCESS_IN_NODE=true
N8N_DIAGNOSTICS_ENABLED=false
```

### File Permissions

```bash
# Restrict access
chmod 600 .env
chmod 700 /path/to/n8n-data
chown -R n8n:n8n /path/to/n8n-data
```

---

## 6. Input Validation

### Validate All Input

**Email validation:**
```javascript
function validateEmail(email) {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
}
```

**SQL Injection Prevention:**
```javascript
// ❌ Vulnerable
const query = `SELECT * FROM users WHERE email = '${email}'`;

// ✅ Safe (parameterized)
const query = 'SELECT * FROM users WHERE email = $1';
const params = [email];
```

**XSS Prevention:**
```javascript
function escapeHtml(text) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return text.replace(/[&<>"']/g, m => map[m]);
}
```

---

## 7. Rate Limiting & DDoS Protection

### Rate Limiting

**Nginx:**
```nginx
limit_req_zone $binary_remote_addr zone=n8n:10m rate=10r/s;

server {
    location / {
        limit_req zone=n8n burst=20 nodelay;
        proxy_pass http://localhost:5678;
    }
}
```

**Application level:**
```javascript
const rateLimit = new Map();

function checkRateLimit(ip, maxRequests = 100, windowMs = 60000) {
  const now = Date.now();
  const window = rateLimit.get(ip) || [];
  
  // Remove old requests
  const valid = window.filter(time => now - time < windowMs);
  
  if (valid.length >= maxRequests) {
    throw new Error('Rate limit exceeded');
  }
  
  valid.push(now);
  rateLimit.set(ip, valid);
  return true;
}
```

### DDoS Protection

**Cloudflare:**
- Enable DDoS protection
- Use Web Application Firewall (WAF)
- Enable bot management

**Basic protection:**
```nginx
# Limit request size
client_max_body_size 10M;

# Timeout settings
client_body_timeout 12s;
client_header_timeout 12s;
```

---

## 8. Audit & Monitoring

### Audit Logging

**Enable audit logs:**
```bash
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=console,file
N8N_LOG_FILE_LOCATION=/var/log/n8n/audit.log
```

**Log important events:**
```javascript
function auditLog(action, user, details) {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'audit',
    action,
    user,
    ip: user.ip,
    details,
    user_agent: user.userAgent
  }));
}
```

### Security Monitoring

**Monitor for:**
- Failed login attempts
- Unusual API usage
- Credential access patterns
- Webhook signature failures
- Configuration changes

---

## 9. Backup Security

### Encrypted Backups

**Encrypt before backup:**
```bash
#!/bin/bash
# backup.sh

BACKUP_FILE="n8n-backup-$(date +%Y%m%d).tar.gz"
ENCRYPTION_KEY="${BACKUP_ENCRYPTION_KEY}"

# Create backup
tar czf $BACKUP_FILE /path/to/n8n-data

# Encrypt
openssl enc -aes-256-cbc -salt -in $BACKUP_FILE \
  -out ${BACKUP_FILE}.enc -k $ENCRYPTION_KEY

# Remove unencrypted
rm $BACKUP_FILE
```

### Backup Access

**Restrict backup access:**
```bash
chmod 600 /backup/*.enc
chown root:root /backup
```

---

## 10. Incident Response

### Security Checklist

**If breach suspected:**
- [ ] Rotate all credentials
- [ ] Check access logs
- [ ] Review recent changes
- [ ] Check for data exfiltration
- [ ] Notify affected users
- [ ] Document incident
- [ ] Update security measures

### Recovery Plan

**Steps:**
1. Isolate affected systems
2. Assess damage
3. Restore from clean backup
4. Rotate credentials
5. Monitor for reoccurrence
6. Document lessons learned

---

## 11. Compliance

### GDPR Considerations

**Data processing:**
- Get explicit consent
- Provide data export
- Enable data deletion
- Document processing activities

**Data retention:**
```bash
# Auto-delete old execution data
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168  # 7 days
```

### SOC 2 Requirements

**Access controls:**
- Multi-factor authentication
- Role-based access
- Audit logging
- Regular access reviews

---

## 12. Security Checklist

### Pre-production

- [ ] HTTPS enabled
- [ ] Strong passwords
- [ ] Credentials secured
- [ ] Firewall configured
- [ ] Backups encrypted
- [ ] Logging enabled
- [ ] Rate limiting setup
- [ ] Input validation implemented

### Production

- [ ] Regular security updates
- [ ] Monitor access logs
- [ ] Rotate credentials
- [ ] Test backup restore
- [ ] Review firewall rules
- [ ] Audit user access
- [ ] Incident response plan
- [ ] Security training for team
