# 🔐 Quản lý Credentials

## Credential Types

### 1. API Key

**Simple key-based authentication**

```
Usage:
  Header: X-API-Key: your-api-key
  Query:  ?api_key=your-api-key
  Body:   { "api_key": "your-api-key" }
```

**Best Practices:**
```bash
# ✅ DO
- Use environment variables for keys
- Rotate keys定期 kỳ
- Use different keys per environment
- Limit key permissions

# ❌ DON'T
- Hardcode keys in workflows
- Share keys across environments
- Commit keys to git
- Use default/demo keys
```

### 2. OAuth2

**Multi-step authentication flow**

```
OAuth2 Flow:
  1. User authorizes app
  2. Get authorization code
  3. Exchange for access token
  4. Use access token for API calls
  5. Refresh token when expired
```

**Setup OAuth2:**
```
1. Create app in provider (Google, GitHub, etc.)
2. Get Client ID & Client Secret
3. Configure redirect URL:
   https://your-n8n.com/rest/oauth2-credential/callback
4. In n8n:
   - Add OAuth2 credential
   - Enter Client ID & Secret
   - Set scopes (permissions)
   - Connect & authorize
```

### 3. Basic Auth

**Username + Password**

```
Header: Authorization: Basic base64(username:password)
```

### 4. Service Account

**JSON key file (Google Cloud)**

```json
{
  "type": "service_account",
  "project_id": "your-project",
  "private_key_id": "...",
  "private_key": "-----BEGIN RSA PRIVATE KEY-----...",
  "client_email": "service@project.iam.gserviceaccount.com"
}
```

---

## 🔒 Encryption

### Encryption Key

**Encrypts stored credentials**

```bash
# Generate encryption key
openssl rand -hex 32

# Set in environment
N8N_ENCRYPTION_KEY=your_32_character_hex_key
```

**Important:**
```
⚠️ MUST do:
  ✓ Set before adding any credentials
  ✓ Store securely (password manager)
  ✓ Backup in secure location
  ✓ Same key across all instances (if clustering)

❌ Never:
  ✗ Use default key in production
  ✗ Commit to git
  ✗ Share publicly
  ✗ Lose it (can't decrypt credentials)
```

---

## 📋 Credential Management

### Sharing Credentials

```
Credentials → Select credential → Share

Options:
  ○ Private (only you)
  ○ Specific users
  ○ All users (be careful!)
```

### Credential Overwrite (Environments)

```bash
# In .env file
export N8N_CREDENTIAL_OVERWRITE_{"id":"cred_123"}='{"apiKey":"prod-key-xyz"}'
```

---

## 🔍 Security Best Practices

### 1. Principle of Least Privilege

```
✓ Use API keys with minimal permissions
✓ Don't use admin credentials if read-only works
✓ Create service accounts with limited scopes
✓ Review permissions定期
```

### 2. Rotation Policy

```
API Keys: Rotate every 90 days
OAuth Tokens: Monitor expiration, refresh automatically
Passwords: Change quarterly
Service Accounts: Rotate keys annually
```

### 3. Monitoring

```
Monitor:
  ✓ Failed authentication attempts
  ✓ Credential usage patterns
  ✓ Expired tokens
  ✓ Unusual API activity

Alert on:
  ✗ Multiple failed logins
  ✗ Credential used from unknown IP
  ✗ Sudden spike in API calls
  ✗ Token refresh failures
```

---

## 🚨 Common Issues

### 1. "Credential not found"

**Solution:**
```
1. Check credentials list
2. Verify sharing settings
3. Recreate if deleted
4. Update workflows
```

### 2. "Invalid credentials"

**Solution:**
```
1. Test credential in n8n
2. Check provider dashboard
3. Regenerate if needed
4. Update credential in n8n
```

### 3. OAuth Token Expired

**Solution:**
```
1. Re-authorize OAuth connection
2. Check scopes are still granted
3. Verify app still has permissions
4. Refresh token manually if needed
```

---

## 📝 Credential Checklist

### Setup
- [ ] Generated encryption key
- [ ] Stored encryption key securely
- [ ] Named credentials consistently
- [ ] Tagged credentials properly
- [ ] Tested credentials work

### Security
- [ ] Used minimal permissions
- [ ] Enabled 2FA on accounts
- [ ] Documented rotation schedule
- [ ] Set up monitoring alerts
- [ ] Restricted credential sharing

### Maintenance
- [ ] Rotated credentials per schedule
- [ ] Reviewed access list 定期
- [ ] Updated expired tokens
- [ ] Removed unused credentials
- [ ] Audited credential usage

---

## 🚀 Next Steps

→ [Binary Data](10-binary-data.md)
→ [Workflow Patterns](11-workflow-patterns.md)
