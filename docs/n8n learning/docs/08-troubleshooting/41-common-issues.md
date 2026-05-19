# Common Issues và Solutions

## 1. Installation Issues

### Issue: Port Already in Use

**Symptom:**
```
Error: listen EADDRINUSE: address already in use :::5678
```

**Solution:**
```bash
# Find process using port
lsof -i :5678

# Kill process
kill -9 <PID>

# Or use different port
docker run -p 8080:5678 n8nio/n8n
```

### Issue: Permission Denied

**Symptom:**
```
Error: EACCES: permission denied
```

**Solution:**
```bash
# Fix volume permissions
docker run --rm -v n8n_data:/data alpine chown -R 1000:1000 /data

# Or run with proper user
docker run -u 1000:1000 n8nio/n8n
```

### Issue: Database Connection Failed

**Symptom:**
```
Error: connect ECONNREFUSED postgres:5432
```

**Solution:**
```bash
# Check database is running
docker-compose ps

# Check database logs
docker-compose logs postgres

# Test connection
docker-compose exec postgres pg_isready -U n8n

# Verify credentials
docker-compose exec postgres psql -U n8n -d n8n
```

---

## 2. Workflow Execution Issues

### Issue: Workflow Not Triggering

**Symptoms:**
- Schedule doesn't fire
- Webhook doesn't receive data
- Manual execution works

**Checklist:**
- [ ] Workflow is Active?
- [ ] Timezone correct?
- [ ] Webhook URL correct?
- [ ] Authentication matches?
- [ ] Request method correct?

**Debug:**
```bash
# Check logs
docker-compose logs -f n8n | grep -i trigger

# Test webhook
curl -v -X POST https://n8n.domain.com/webhook/test
```

### Issue: Node Timeout

**Symptom:**
```
Error: Node execution timed out after 300 seconds
```

**Solutions:**
```bash
# Increase timeout
EXECUTIONS_TIMEOUT=600

# Or for specific node
NODE_OPTIONS=--max-old-space-size=4096
```

**Optimize:**
- Reduce data volume
- Use pagination
- Batch operations
- Optimize queries

### Issue: Memory Error

**Symptom:**
```
Error: JavaScript heap out of memory
```

**Solutions:**
```bash
# Increase heap size
NODE_OPTIONS=--max-old-space-size=4096

# Use filesystem mode for binary
N8N_DEFAULT_BINARY_DATA_MODE=filesystem

# Process in batches
# Split large workflows
```

---

## 3. API Integration Issues

### Issue: Authentication Failed

**Symptom:**
```
Error: 401 Unauthorized
```

**Checklist:**
- [ ] Credentials correct?
- [ ] Token expired?
- [ ] Scopes sufficient?
- [ ] IP allowed?

**Fix:**
```javascript
// Test credentials manually
curl -H "Authorization: Bearer TOKEN" \
  https://api.example.com/endpoint

// Refresh OAuth token
// Reconnect via OAuth in N8N
```

### Issue: Rate Limiting

**Symptom:**
```
Error: 429 Too Many Requests
```

**Solution:**
```javascript
// Implement throttling
const response = await fetch(url);

if (response.status === 429) {
  const retryAfter = response.headers.get('Retry-After') || 60;
  await new Promise(r => setTimeout(r, retryAfter * 1000));
  // Retry
}
```

**Prevention:**
- Add Wait nodes between API calls
- Use batch operations
- Cache responses
- Respect rate limits

### Issue: Invalid Response Format

**Symptom:**
```
Error: Cannot read property 'X' of undefined
```

**Solution:**
```javascript
// Safe access with optional chaining
const value = response?.data?.items?.[0]?.name;

// With default
const name = value ?? 'Unknown';
```

---

## 4. Webhook Issues

### Issue: Webhook 404

**Symptom:**
```
POST https://n8n.domain.com/webhook/test 404
```

**Causes & Solutions:**

| Cause | Solution |
|-------|----------|
| Workflow not active | Activate workflow |
| Wrong URL | Check path |
| Test vs Production | Use correct URL |
| Method mismatch | Check HTTP method |

**Debug:**
```bash
# Test webhook
curl -v -X POST https://n8n.domain.com/webhook/test \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Check N8N logs
docker-compose logs n8n | grep webhook
```

### Issue: Webhook Signature Invalid

**Symptom:**
```
Error: Invalid webhook signature
```

**Solution:**
```javascript
const crypto = require('crypto');

// Verify signature
function verifySignature(payload, signature, secret) {
  const expected = 'sha256=' + crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  
  return signature === expected;
}
```

---

## 5. Database Issues

### Issue: Query Failed

**Symptom:**
```
Error: relation "users" does not exist
```

**Solutions:**
- Check table name (case-sensitive)
- Verify schema
- Check permissions
- Test query manually

**Debug:**
```sql
-- List tables
\dt

-- Check table structure
\d users

-- Test query
SELECT * FROM users LIMIT 1;
```

### Issue: Connection Pool Exhausted

**Symptom:**
```
Error: too many connections for role "n8n"
```

**Solution:**
```bash
# Increase connection limit
ALTER ROLE n8n CONNECTION LIMIT 50;

# Or optimize connection usage
# Close connections after use
# Use connection pooling
```

---

## 6. Email Issues

### Issue: Email Not Sending

**Symptom:**
```
Error: Connection refused
```

**Checklist:**
- [ ] SMTP server correct?
- [ ] Port correct (587/465)?
- [ ] Credentials valid?
- [ ] TLS enabled?
- [ ] From address valid?

**Test SMTP:**
```bash
# Test connection
telnet smtp.gmail.com 587

# Or use openssl
openssl s_client -connect smtp.gmail.com:587 -starttls smtp
```

### Issue: Emails Going to Spam

**Causes:**
- No SPF/DKIM records
- Poor sender reputation
- Spammy content
- No unsubscribe link

**Fix:**
```
Add DNS records:
SPF: v=spf1 include:_spf.google.com ~all
DKIM: [Generate in email provider]
DMARC: v=DMARC1; p=none
```

---

## 7. Performance Issues

### Issue: Slow Execution

**Symptom:**
```
Workflow takes > 5 minutes
```

**Optimization:**
```javascript
// ❌ Slow: Sequential API calls
for (const item of items) {
  await api.call(item);
}

// ✅ Fast: Batch API call
await api.callBatch(items);
```

**Checklist:**
- [ ] Use batch operations
- [ ] Implement caching
- [ ] Optimize queries
- [ ] Use pagination
- [ ] Increase resources

### Issue: Queue Backlog

**Symptom:**
```
Queue size growing continuously
```

**Solutions:**
```bash
# Add more workers
docker-compose up -d --scale n8n-worker=5

# Check worker logs
docker-compose logs n8n-worker

# Increase worker timeout
WORKER_TIMEOUT=600
```

---

## 8. Credential Issues

### Issue: OAuth Expired

**Symptom:**
```
Error: Token expired
```

**Fix:**
1. Go to Credentials
2. Click "Reconnect"
3. Complete OAuth flow
4. Test connection

### Issue: Credential Not Showing

**Symptom:**
- Credential created but not available in node

**Fix:**
- Check credential type matches node
- Refresh browser
- Check permissions
- Verify credential is not deleted

---

## 9. UI Issues

### Issue: Canvas Not Loading

**Symptom:**
- Blank canvas
- Nodes not visible

**Fix:**
```bash
# Clear browser cache
# Hard refresh: Cmd+Shift+R

# Or restart N8N
docker-compose restart n8n
```

### Issue: Expression Not Working

**Symptom:**
- Expression returns undefined
- Wrong value

**Debug:**
```javascript
// Print full input
{{ JSON.stringify($input.all(), null, 2) }}

// Check field exists
{{ $json.hasOwnProperty('field') }}

// Test with simple value
{{ 'test' }}
```

---

## 10. General Debugging

### Enable Debug Mode

```bash
# Environment variables
N8N_LOG_LEVEL=debug
NODE_ENV=development

# Restart
docker-compose restart n8n
```

### Check Logs

```bash
# All logs
docker-compose logs -f n8n

# Filter errors
docker-compose logs n8n | grep ERROR

# Filter specific workflow
docker-compose logs n8n | grep "workflow-name"
```

### Common Debug Steps

1. **Check execution history**
   - Go to Executions page
   - Find failed execution
   - Check error message

2. **Test node in isolation**
   - Execute node directly
   - Check input/output

3. **Verify credentials**
   - Test connection
   - Check expiration

4. **Check external services**
   - API status page
   - Database connectivity

5. **Review recent changes**
   - Git diff
   - Configuration changes

---

## Quick Reference

### Emergency Commands

```bash
# Restart N8N
docker-compose restart n8n

# View logs
docker-compose logs -f n8n

# Check status
docker-compose ps

# Health check
curl http://localhost:5678/healthz

# Backup
docker-compose exec postgres pg_dump -U n8n n8n > backup.sql

# Restore
docker-compose exec -T postgres psql -U n8n n8n < backup.sql
```

### Support Resources

- 📖 [Documentation](https://docs.n8n.io)
- 💬 [Community Forum](https://community.n8n.io)
- 🐛 [GitHub Issues](https://github.com/n8n-io/n8n/issues)
- 📧 [Support](https://n8n.io/support)
