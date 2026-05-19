# 🔧 Cài đặt và cấu hình N8N

## 📋 Yêu cầu hệ thống

### Minimum Requirements
- **CPU**: 1 core
- **RAM**: 2GB (4GB recommended)
- **Storage**: 1GB
- **Node.js**: 18.x hoặc 20.x (nếu cài qua npm)

### Recommended (Production)
- **CPU**: 2+ cores
- **RAM**: 4-8GB
- **Storage**: 10GB+ SSD
- **Database**: PostgreSQL (thay vì SQLite)

---

## 🐳 Phương pháp 1: Docker Compose (Recommended)

### Ưu điểm
✅ Dễ setup, production-ready
✅ Isolated environment
✅ Dễ backup và migrate
✅ Có thể scale với queue mode

### Cài đặt

**Bước 1**: Tạo thư mục project
```bash
mkdir n8n-deployment && cd n8n-deployment
mkdir .n8n  # Persistent data
```

**Bước 2**: Tạo `docker-compose.yml`
```yaml
version: '3.8'

services:
  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      - TZ=Asia/Ho_Chi_Minh
    volumes:
      - ./.n8n:/home/node/.n8n
```

**Bước 3**: Start
```bash
docker compose up -d
```

**Bước 4**: Truy cập
```
http://localhost:5678
```

### Production với PostgreSQL

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: n8n-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=your_secure_password
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 10s
      timeout: 5s
      retries: 5

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=your_secure_password
      - DB_POSTGRESDB_DATABASE=n8n
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      - TZ=Asia/Ho_Chi_Minh
    volumes:
      - ./.n8n:/home/node/.n8n
    ports:
      - "5678:5678"

volumes:
  postgres_data:
```

---

## 💻 Phương pháp 2: npm (Development)

```bash
# Cài đặt Node.js 18+
nvm install 18

# Cài đặt n8n
npm install n8n -g

# Start n8n
n8n start

# Hoặc với tunnel cho webhooks
n8n start --tunnel
```

---

## ⚙️ Cấu hình quan trọng

### Environment Variables

```bash
# Server
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=your_password
DB_POSTGRESDB_DATABASE=n8n

# Security
N8N_ENCRYPTION_KEY=your_32_character_encryption_key
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_password

# Queue Mode (Production)
EXECUTIONS_MODE=queue
QUEUE_BULL_REDIS_HOST=redis
QUEUE_BULL_REDIS_PORT=6379

# Binary Data
N8N_DEFAULT_BINARY_DATA_MODE=s3
N8N_DEFAULT_BINARY_DATA_MODE_S3_BUCKET=n8n-binary-data
```

---

## 🔒 Reverse Proxy (HTTPS)

### Nginx

```nginx
server {
    listen 80;
    server_name n8n.your-domain.com;
    
    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Với Let's Encrypt

```bash
sudo certbot --nginx -d n8n.your-domain.com
```

---

## ✅ Checklist Production

- [ ] Sử dụng PostgreSQL thay vì SQLite
- [ ] Enable HTTPS với reverse proxy
- [ ] Set N8N_ENCRYPTION_KEY
- [ ] Configure queue mode cho high-volume
- [ ] Setup backup tự động
- [ ] Configure logging và monitoring
- [ ] Set execution timeouts
- [ ] Enable basic auth hoặc SSO

---

## 🚀 Next Steps

→ [Core Concepts](03-core-concepts.md)
→ [Workflow Basics](04-workflow-basics.md)
