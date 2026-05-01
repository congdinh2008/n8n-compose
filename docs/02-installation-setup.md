# 02. Cài đặt và cấu hình N8N

## 📋 Mục lục
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Phương pháp cài đặt](#phương-pháp-cài-đặt)
- [Docker Compose (Recommended)](#docker-compose-recommended)
- [Cài đặt với npm](#cài-đặt-với-npm)
- [Cấu hình production](#cấu-hình-production)
- [Database configuration](#database-configuration)
- [SSL và HTTPS](#ssl-và-https)
- [Backup và restore](#backup-và-restore)
- [Troubleshooting](#troubleshooting)

---

## Yêu cầu hệ thống

### Tối thiểu (Development)

| Thành phần | Yêu cầu |
|------------|---------|
| CPU | 1 core |
| RAM | 1 GB |
| Disk | 5 GB |
| OS | Linux, macOS, Windows (WSL) |

### Production (Small team)

| Thành phần | Yêu cầu |
|------------|---------|
| CPU | 2-4 cores |
| RAM | 4-8 GB |
| Disk | 20 GB+ SSD |
| OS | Linux (Ubuntu/Debian recommended) |

### Production (Enterprise)

| Thành phần | Yêu cầu |
|------------|---------|
| CPU | 4+ cores |
| RAM | 8-16 GB+ |
| Disk | 50 GB+ SSD |
| OS | Linux (Ubuntu LTS) |
| Database | PostgreSQL |
| Queue | Redis |

---

## Phương pháp cài đặt

| Phương pháp | Độ khó | Phù hợp | Maintain |
|-------------|--------|---------|----------|
| **Docker Compose** | Dễ | Tất cả | ✅ Dễ |
| **npm** | Trung bình | Development | Trung bình |
| **N8N Cloud** | Rất dễ | Production | ✅ N8N lo |
| **Kubernetes** | Khó | Enterprise | Phức tạp |

---

## Docker Compose (Recommended)

### 1. Basic Setup

Tạo file `docker-compose.yml`:

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
    volumes:
      - n8n_data:/home/node/.n8n
      - ./local-files:/files

volumes:
  n8n_data:
```

Khởi chạy:

```bash
docker-compose up -d

# Kiểm tra logs
docker-compose logs -f n8n
```

Truy cập: `http://localhost:5678`

### 2. Production Setup với PostgreSQL và Redis

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      # Basic
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.yourdomain.com
      
      # Database
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${DB_PASSWORD}
      - DB_POSTGRESDB_SCHEMA=public
      
      # Queue Mode (Redis)
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      
      # Security
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${ADMIN_PASSWORD}
      
      # Timezone
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      - TZ=Asia/Ho_Chi_Minh
      
      # Email
      - N8N_EMAIL_MODE=smtp
      - N8N_SMTP_HOST=smtp.gmail.com
      - N8N_SMTP_PORT=587
      - N8N_SMTP_USER=your-email@gmail.com
      - N8N_SMTP_PASS=${SMTP_PASSWORD}
      - N8N_SMTP_SENDER=n8n@yourdomain.com
      
    volumes:
      - n8n_data:/home/node/.n8n
      - ./local-files:/files
    depends_on:
      - postgres
      - redis
    networks:
      - n8n-network

  postgres:
    image: postgres:15-alpine
    container_name: n8n-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - n8n-network

  redis:
    image: redis:7-alpine
    container_name: n8n-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - n8n-network

volumes:
  n8n_data:
  postgres_data:
  redis_data:

networks:
  n8n-network:
    driver: bridge
```

Tạo file `.env`:

```bash
# Database
DB_PASSWORD=your-secure-db-password-here

# Admin
ADMIN_PASSWORD=your-admin-password-here

# Redis
REDIS_PASSWORD=your-redis-password-here

# SMTP
SMTP_PASSWORD=your-smtp-password-here
```

Khởi chạy:

```bash
docker-compose up -d
```

### 3. Với Nginx Reverse Proxy và SSL

Thêm Nginx vào docker-compose:

```yaml
services:
  # ... (n8n, postgres, redis như trên)
  
  nginx:
    image: nginx:alpine
    container_name: n8n-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certs:/etc/nginx/certs
    depends_on:
      - n8n
    networks:
      - n8n-network
```

Tạo `nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream n8n {
        server n8n:5678;
    }

    server {
        listen 80;
        server_name n8n.yourdomain.com;
        
        # Redirect HTTP to HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name n8n.yourdomain.com;

        ssl_certificate /etc/nginx/certs/cert.pem;
        ssl_certificate_key /etc/nginx/certs/key.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            proxy_pass http://n8n;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }

        location /webhook/ {
            proxy_pass http://n8n;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

---

## Cài đặt với npm

### Yêu cầu

- Node.js 18.x hoặc 20.x
- npm 9+

### Cài đặt

```bash
# Cài n8n global
npm install n8n -g

# Hoặc cài trong project
npm init -y
npm install n8n

# Khởi chạy
n8n start

# Với custom port
n8n start --port 5678
```

### Service file (Systemd)

Tạo `/etc/systemd/system/n8n.service`:

```ini
[Unit]
Description=n8n workflow automation
After=network.target

[Service]
Type=simple
User=n8n
Group=n8n
Environment=NODE_ENV=production
ExecStart=/usr/bin/n8n start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# Reload và start service
sudo systemctl daemon-reload
sudo systemctl enable n8n
sudo systemctl start n8n

# Kiểm tra status
sudo systemctl status n8n

# Xem logs
sudo journalctl -u n8n -f
```

---

## Cấu hình production

### Environment Variables quan trọng

```bash
# === SECURITY ===
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure-password

# === DATABASE ===
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=secure-password

# === QUEUE MODE ===
EXECUTIONS_MODE=queue
QUEUE_BULL_REDIS_HOST=localhost
QUEUE_BULL_REDIS_PORT=6379
QUEUE_BULL_REDIS_PASSWORD=secure-password

# === EXECUTIONS ===
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_MAX_AGE=168
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_PRUNE_MAX_COUNT=10000

# === WEBHOOK ===
WEBHOOK_URL=https://n8n.yourdomain.com
N8N_PROTOCOL=https

# === EMAIL ===
N8N_EMAIL_MODE=smtp
N8N_SMTP_HOST=smtp.gmail.com
N8N_SMTP_PORT=587
N8N_SMTP_USER=your-email@gmail.com
N8N_SMTP_PASS=your-password
N8N_SMTP_SENDER=n8n@yourdomain.com

# === LOGGING ===
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=console

# === TIMEZONE ===
GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
TZ=Asia/Ho_Chi_Minh

# === SECURITY HEADERS ===
N8N_SECURE_COOKIE=true
N8N_SECURE_MODE=true
```

### Performance Tuning

```bash
# Số lượng workflows chạy đồng thời
N8N_CONCURRENCY_PRODUCTION_LIMIT=10

# Giới hạn memory cho execution
# (Đặt trong workflow settings)

# Pruning executions cũ
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_PRUNE_MAX_COUNT=10000
EXECUTIONS_DATA_MAX_AGE=168  # 7 ngày (giờ)
```

---

## Database configuration

### SQLite (Default)

```bash
# Không cần cấu hình, tự động dùng
# Phù hợp: Development, testing, cá nhân
```

### PostgreSQL (Production)

```bash
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=secure-password
DB_POSTGRESDB_SCHEMA=public
```

Tạo database:

```sql
CREATE DATABASE n8n;
CREATE USER n8n WITH PASSWORD 'secure-password';
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
```

### MySQL

```bash
DB_TYPE=mysqldb
DB_MYSQLDB_HOST=localhost
DB_MYSQLDB_PORT=3306
DB_MYSQLDB_DATABASE=n8n
DB_MYSQLDB_USER=n8n
DB_MYSQLDB_PASSWORD=secure-password
```

---

## SSL và HTTPS

### 1. Let's Encrypt với Certbot

```bash
# Cài certbot
sudo apt install certbot python3-certbot-nginx

# Tạo certificate
sudo certbot certonly --nginx -d n8n.yourdomain.com

# Auto-renew
sudo crontab -e
# Thêm: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 2. Tự-signed (Development)

```bash
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout key.pem \
  -out cert.pem \
  -subj "/CN=localhost"
```

---

## Backup và restore

### Backup

```bash
# 1. Backup Docker volumes
docker-compose down
tar -czf n8n-backup-$(date +%Y%m%d).tar.gz ./n8n_data

# 2. Export workflows từ UI
# Settings > Export workflow

# 3. Backup database (PostgreSQL)
pg_dump -U n8n -h localhost n8n > n8n-db-backup.sql

# 4. Backup toàn bộ
tar -czf n8n-full-backup-$(date +%Y%m%d).tar.gz \
  ./n8n_data \
  ./postgres_data \
  ./docker-compose.yml \
  ./.env
```

### Restore

```bash
# 1. Stop containers
docker-compose down

# 2. Restore volumes
tar -xzf n8n-backup-20240101.tar.gz

# 3. Restore database
psql -U n8n -h localhost n8n < n8n-db-backup.sql

# 4. Start
docker-compose up -d
```

### Automated Backup Script

```bash
#!/bin/bash
# backup-n8n.sh

BACKUP_DIR="/backup/n8n"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

mkdir -p $BACKUP_DIR

# Backup Docker volumes
docker-compose down
tar -czf $BACKUP_DIR/n8n-$DATE.tar.gz ./n8n_data
docker-compose up -d

# Backup database
pg_dump -U n8n -h localhost n8n | gzip > $BACKUP_DIR/n8n-db-$DATE.sql.gz

# Cleanup old backups
find $BACKUP_DIR -type f -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $DATE"
```

Setup cron job:

```bash
# Backup hàng ngày lúc 2h sáng
0 2 * * * /path/to/backup-n8n.sh >> /var/log/n8n-backup.log 2>&1
```

---

## Troubleshooting

### N8N không start được

```bash
# Kiểm tra logs
docker-compose logs n8n

# Kiểm tra container status
docker-compose ps

# Restart
docker-compose restart n8n
```

### Lỗi kết nối Database

```bash
# Test kết nối PostgreSQL
psql -U n8n -h localhost -d n8n -c "SELECT 1"

# Kiểm tra credentials
docker-compose exec n8n env | grep DB_
```

### Lỗi Webhook

```bash
# Kiểm tra WEBHOOK_URL
docker-compose exec n8n env | grep WEBHOOK

# Test webhook
curl -X POST https://n8n.yourdomain.com/webhook/test \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

### Performance Issues

```bash
# Kiểm tra resource usage
docker stats

# Kiểm tra số executions
docker-compose exec postgres psql -U n8n -c \
  "SELECT COUNT(*) FROM execution_entity;"

# Prune executions cũ
docker-compose exec n8n n8n prune-executions --before 7d
```

### Memory Leak

```bash
# Giới hạn memory trong Docker
# docker-compose.yml
services:
  n8n:
    deploy:
      resources:
        limits:
          memory: 4G
```

---

## 💡 Best Practices

### Setup

1. ✅ Luôn dùng PostgreSQL cho production
2. ✅ Bật queue mode với Redis cho nhiều workflows
3. ✅ Dùng environment variables cho credentials
4. ✅ Setup backup tự động
5. ✅ Bật HTTPS cho webhooks

### Security

1. ✅ Đổi password mặc định ngay
2. ✅ Dùng strong passwords
3. ✅ Không commit `.env` file
4. ✅ Giới hạn IP access nếu có thể
5. ✅ Update N8N thường xuyên

### Performance

1. ✅ Prune executions cũ định kỳ
2. ✅ Giới hạn concurrency phù hợp với server
3. ✅ Dùng SSD cho database
4. ✅ Monitor resource usage
5. ✅ Tách database sang server riêng nếu cần

---

## 🔗 Tham khảo

- [N8N Installation Guide](https://docs.n8n.io/hosting/installation/)
- [N8N Configuration](https://docs.n8n.io/hosting/configuration/)
- [N8N Docker](https://docs.n8n.io/hosting/installation/docker/)

---

**[← Quay lại: 01. Giới thiệu](01-introduction.md)** | **[Tiếp theo: 03. Core Concepts →](03-core-concepts.md)**
