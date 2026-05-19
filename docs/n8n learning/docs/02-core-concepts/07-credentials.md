# Credentials và Bảo mật

## 1. Credentials trong N8N

### Credentials là gì?
**Credentials** là thông tin xác thực được lưu trữ an toàn trong N8N, cho phép các nodes kết nối với services bên ngoài mà không cần hardcode thông tin nhạy cảm.

### Credential Types

| Type | Authentication Method | Services |
|------|----------------------|----------|
| **OAuth2** | OAuth 2.0 flow | Google, GitHub, Slack |
| **API Key** | Static key in header/query | Most REST APIs |
| **Basic Auth** | Username/Password | Simple APIs, databases |
| **Token** | Bearer token | JWT, custom APIs |
| **Database** | Host/User/Password | PostgreSQL, MySQL, MongoDB |
| **Private Key** | SSH/RSA keys | SFTP, Git |

---

## 2. Managing Credentials

### Create New Credential

**Steps:**
1. Click **🔑 Credentials** trong sidebar
2. Click **[+ Add Credential]**
3. Select type
4. Enter authentication details
5. Test connection
6. Save

### Credential Fields

**Common fields:**
```
Name: [Descriptive Name]
Type: [Service Type]
┌─────────────────────────────────────┐
│ Client ID:     [_______________]    │
│ Client Secret: [_______________]    │
│ Access Token:  [_______________]    │
│ Refresh Token: [_______________]    │
│                                    │
│ Auth URL:      [_______________]    │
│ Token URL:     [_______________]    │
│ Scope:         [_______________]    │
└─────────────────────────────────────┘

[✓] Connect using OAuth
    Opens provider's authorization page
```

### Credential Scopes

**OAuth Scopes:**
```
Google Drive:
☑ drive.readonly
☑ drive.file
☑ drive.metadata.readonly

GitHub:
☑ repo
☑ user
☑ admin:org
```

💡 **Luôn yêu cầu scopes tối thiểu cần thiết**

---

## 3. Using Credentials

### In Nodes

**Select credential:**
```
Node → Authentication → Predefined Credential Type
                    → Select: [Google Drive OAuth ▼]
                    → Credential: [My Drive - Marketing ▼]
```

### Share across workflows

**Credential usage:**
```
Credential "Production DB" used by:
- Daily Report workflow
- User Sync workflow
- Backup workflow
```

💡 **Một credential có thể được dùng bởi nhiều workflows**

---

## 4. Credential Storage

### How credentials are stored

**Encrypted in database:**
```
Encryption Key: N8N_ENCRYPTION_KEY
Algorithm: AES-256-GCM
Storage: Database (encrypted)
```

### Export/Import

**Export:**
```bash
n8n export:credentials --all --output=creds.json

# Encrypt export
n8n export:credentials --all --output=creds.json --encrypt
```

**Import:**
```bash
n8n import:credentials --input=creds.json
```

### Backup

```bash
# Include credentials in backup
n8n export:credentials --all --output=backup/credentials.json

# Restore
n8n import:credentials --input=backup/credentials.json
```

⚠️ **Không commit credentials vào git**

---

## 5. OAuth2 Setup Examples

### Google OAuth2

**Step 1: Create Google Cloud Project**
1. Go to https://console.cloud.google.com
2. Create project
3. Enable APIs (Drive, Sheets, Gmail)
4. Go to Credentials → OAuth 2.0 Client IDs
5. Create OAuth client ID
6. Set redirect URL: `https://n8n.yourdomain.com/oauth2/callback`

**Step 2: Configure in N8N**
```
Client ID: [from Google Console]
Client Secret: [from Google Console]
Scope: https://www.googleapis.com/auth/drive.readonly
```

**Step 3: Connect**
1. Click "Connect using OAuth"
2. Login with Google account
3. Grant permissions
4. Redirect back to N8N
5. Credential saved

### GitHub OAuth2

**Step 1: Create GitHub App**
1. Go to https://github.com/settings/developers
2. New OAuth App
3. Set callback URL
4. Get Client ID and Secret

**Step 2: Configure in N8N**
```
Client ID: [from GitHub]
Client Secret: [from GitHub]
Scope: repo,user
```

---

## 6. API Key Setup

### Header Authentication

```
Authentication: Header Auth
Name: [API Key - Service Name]
Header Name: X-API-Key
Header Value: your_api_key_here
```

### Query Parameter Authentication

```
Authentication: Query Auth
Name: [API Key - Service Name]
Query Name: api_key
Query Value: your_api_key_here
```

### Bearer Token

```
Authentication: Bearer Token
Name: [Token - Service Name]
Token: your_jwt_token_here
```

---

## 7. Database Credentials

### PostgreSQL

```
Type: PostgreSQL
Host: postgres.example.com
Port: 5432
Database: production
User: n8n_reader
Password: [secure_password]

Options:
☑ SSL Connection
☐ Skip SSL verification
```

### MongoDB

```
Type: MongoDB
Connection String: mongodb://user:pass@host:27017/dbname
Database: analytics

Options:
☑ SSL Connection
☐ Skip SSL verification
```

---

## 8. Credential Security Best Practices

### ✅ Do

- Use strong, unique passwords
- Rotate credentials regularly
- Use least privilege principle
- Enable MFA on provider accounts
- Use OAuth2 when available
- Monitor credential usage
- Audit access logs

### ❌ Don't

- Hardcode credentials in workflows
- Share credentials via email/chat
- Use same password across services
- Store credentials in plain text
- Commit credentials to git
- Use production credentials in dev
- Skip credential rotation

---

## 9. Credential Rotation

### When to rotate

**Schedule:**
- API keys: Every 90 days
- Database passwords: Every 60 days
- OAuth tokens: When suspicious activity

**Events:**
- Employee leaves
- Security breach
- Credential exposed
- Audit requirement

### Rotation Process

```
1. Create new credential
2. Update workflows to use new credential
3. Test all workflows
4. Deactivate old credential
5. Delete old credential after confirmation
```

---

## 10. Troubleshooting Credentials

### Common Issues

| Issue | Solution |
|-------|----------|
| OAuth expired | Reconnect via OAuth |
| Invalid credentials | Check username/password |
| Token expired | Refresh token |
| Permission denied | Check scopes/roles |
| Connection timeout | Check network/firewall |

### Debug Steps

```
1. Test connection in credential settings
2. Check provider API status
3. Verify credentials manually
4. Check network connectivity
5. Review error logs
```

### Error Messages

| Error | Meaning | Fix |
|-------|---------|-----|
| 401 Unauthorized | Invalid credentials | Update credentials |
| 403 Forbidden | Insufficient permissions | Request more scopes |
| 429 Too Many Requests | Rate limited | Wait and retry |
| 500 Internal Error | Provider issue | Check provider status |

---

## 11. Credential Management Workflow

### Automated monitoring

```
Schedule (weekly) → Check credential expiry → 
If expiring soon → Notify admin → Rotate if needed
```

### Implementation

```javascript
const credentials = $('Get Credentials').all();
const soon = new Date();
soon.setDate(soon.getDate() + 30); // 30 days warning

const expiring = credentials.filter(cred => 
  new Date(cred.json.expiry_date) < soon
);

return expiring.map(cred => ({
  json: {
    name: cred.json.name,
    type: cred.json.type,
    expires: cred.json.expiry_date,
    days_left: Math.floor(
      (new Date(cred.json.expiry_date) - new Date()) / (1000*60*60*24)
    ),
    workflows: cred.json.used_by.length
  }
}));
```
