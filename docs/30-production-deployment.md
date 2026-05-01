# 🚀 Production Deployment

## 📋 Pre-Production Checklist

### Infrastructure
- [ ] Production server provisioned (AWS/GCP/Azure)
- [ ] PostgreSQL database setup
- [ ] Redis for queue mode
- [ ] SSL certificate configured
- [ ] Reverse proxy (Nginx/Traefik) setup
- [ ] Domain configured with DNS
- [ ] Firewall rules configured
- [ ] Backup strategy implemented

### N8N Configuration
- [ ] Environment variables set
- [ ] Encryption key generated and stored
- [ ] Queue mode enabled
- [ ] Binary data storage configured (S3)
- [ ] Execution timeouts set
- [ ] Logging configured
- [ ] Metrics enabled
- [ ] Source control setup

### Security
- [ ] HTTPS enforced
- [ ] Basic auth or SSO enabled
- [ ] Webhook authentication
- [ ] API keys rotated
- [ ] Rate limiting configured
- [ ] IP whitelisting (if applicable)
- [ ] 2FA enabled for users

---

## 🏗️ Production Architecture

### Single Instance (Small Scale)

```
┌──────────────────────────────────┐
│         Load Balancer            │
│         (Optional)               │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│         Nginx (HTTPS)            │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│        n8n Instance              │
│  ┌────────────────────────────┐  │
│  │ Main Process               │  │
│  │ Task Runners               │  │
│  └────────────────────────────┘  │
└───────┬──────────────┬───────────┘
        │              │
        ▼              ▼
┌──────────────┐ ┌──────────────┐
│ PostgreSQL   │ │     S3       │
│ (Database)   │ │ (Binary)     │
└──────────────┘ └──────────────┘
```

### Cluster Setup (Large Scale)

```
┌──────────────────────────────────┐
│         Load Balancer            │
└──────┬──────────┬──────────┬─────┘
       │          │          │
       ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐
│ n8n-1  │ │ n8n-2  │ │ n8n-3  │
│(Webhook│ │(Main   │ │(Main   │
│ only)  │ │ +Job)  │ │ +Job)  │
└────┬───┘ └────┬───┘ └────┬───┘
     │          │          │
     └──────────┴──────────┘
                │
                ▼
     ┌──────────────────────┐
     │   Redis (Queue)      │
     └──────────┬───────────┘
                │
     ┌──────────┴───────────┐
     │                      │
     ▼                      ▼
┌──────────┐          ┌──────────┐
│PostgreSQL│          │    S3    │
└──────────┘          └──────────┘
```

---

## 🔧 Docker Compose Production

### Full Production Setup

```yaml
version: '3.8'

services:
  # Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: n8n-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certs:/etc/letsencrypt
    depends_on:
      - n8n-web
      - n8n-worker
    networks:
      - n8n-network

  # n8n Main Instance (Webhook + Editor)
  n8n-web:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n-web
    restart: unless-stopped
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=https://n8n.your-domain.com/
      
      # Database
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - DB_POSTGRESDB_DATABASE=n8n
      
      # Queue Mode
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - QUEUE_BULL_REDIS_PASSWORD=${REDIS_PASSWORD}
      
      # Binary Data
      - N8N_DEFAULT_BINARY_DATA_MODE=s3
      - N8N_DEFAULT_BINARY_DATA_MODE_S3_BUCKET=${S3_BUCKET}
      - N8N_DEFAULT_BINARY_DATA_MODE_S3_REGION=${AWS_REGION}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      
      # Security
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_ADMIN_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_ADMIN_PASSWORD}
      
      # Performance
      - N8N_CONCURRENCY_PRODUCTION=10
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168
      
      # Timezone
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      - TZ=Asia/Ho_Chi_Minh
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n-network
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  # n8n Worker (Job Processing)
  n8n-worker:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n-worker
    restart: unless-stopped
    command: worker
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - DB_POSTGRESDB_DATABASE=n8n
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - QUEUE_BULL_REDIS_PASSWORD=${REDIS_PASSWORD}
      - N8N_DEFAULT_BINARY_DATA_MODE=s3
      - N8N_DEFAULT_BINARY_DATA_MODE_S3_BUCKET=${S3_BUCKET}
      - N8N_DEFAULT_BINARY_DATA_MODE_S3_REGION=${AWS_REGION}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      - TZ=Asia/Ho_Chi_Minh
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n-network
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  # PostgreSQL
  postgres:
    image: postgres:16-alpine
    container_name: n8n-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - n8n-network

  # Redis
  redis:
    image: redis:7-alpine
    container_name: n8n-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
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

---

## 🔒 SSL/HTTPS Setup

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name n8n.your-domain.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name n8n.your-domain.com;
    
    ssl_certificate /etc/letsencrypt/live/n8n.your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/n8n.your-domain.com/privkey.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    client_max_body_size 50M;
    
    location / {
        proxy_pass http://n8n-web:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location /webhook/ {
        proxy_pass http://n8n-web:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /webhook-test/ {
        proxy_pass http://n8n-web:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Let's Encrypt

```bash
# Install certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d n8n.your-domain.com

# Auto-renewal (cron)
echo "0 0 * * * certbot renew --quiet" | sudo tee -a /etc/crontab
```

---

## 📊 Monitoring Setup

### Prometheus + Grafana

**Enable Metrics:**
```bash
N8N_METRICS=true
N8N_METRICS_PREFIX=n8n_
```

**Prometheus Config:**
```yaml
scrape_configs:
  - job_name: 'n8n'
    scrape_interval: 15s
    static_configs:
      - targets: ['n8n-web:5678']
```

**Key Metrics:**
```
n8n_workflow_started_total
n8n_workflow_errors_total
n8n_workflow_duration_seconds
n8n_node_executions_total
n8n_webhook_requests_total
n8n_queue_jobs_waiting
n8n_queue_jobs_active
```

### Log Aggregation

**File Logging:**
```bash
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=file
N8N_LOG_FILE_PATH=/var/log/n8n/n8n.log
N8N_LOG_FILE_MAXSIZE=100
N8N_LOG_FILE_MAX_AGE=30
```

**Ship logs to ELK/Loki:**
```yaml
# Filebeat
filebeat.inputs:
  - type: log
    paths:
      - /var/log/n8n/*.log
    fields:
      service: n8n
```

---

## 💾 Backup Strategy

### Database Backup

```bash
#!/bin/bash
# backup-db.sh

BACKUP_DIR="/backup/n8n"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

docker exec n8n-postgres pg_dump -U n8n n8n | \
  gzip > $BACKUP_DIR/db_$TIMESTAMP.sql.gz

# Keep only last 7 days
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +7 -delete

echo "Database backup completed: $TIMESTAMP"
```

### Volume Backup

```bash
#!/bin/bash
# backup-volumes.sh

BACKUP_DIR="/backup/n8n"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

docker run --rm \
  -v n8n_data:/data:ro \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/n8n_data_$TIMESTAMP.tar.gz -C /data .

echo "Volume backup completed: $TIMESTAMP"
```

### Automated Backups (Cron)

```bash
# Daily backup at 2 AM
0 2 * * * /opt/n8n/backup-db.sh >> /var/log/n8n-backup.log 2>&1

# Weekly full backup on Sunday
0 3 * * 0 /opt/n8n/backup-volumes.sh >> /var/log/n8n-backup.log 2>&1
```

---

## 🚨 Alerting

### Health Check

```bash
#!/bin/bash
# health-check.sh

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  https://n8n.your-domain.com/healthz)

if [ "$RESPONSE" != "200" ]; then
  # Send alert
  curl -X POST -H 'Content-type: application/json' \
    --data '{"text":"🚨 n8n health check failed!"}' \
    $SLACK_WEBHOOK_URL
fi
```

### Cron Health Check

```bash
# Check every 5 minutes
*/5 * * * * /opt/n8n/health-check.sh
```

---

## 🔄 Deployment Process

### Blue-Green Deployment

```
1. Deploy new version to green environment
2. Run smoke tests
3. Switch load balancer to green
4. Monitor for 10 minutes
5. If OK: Keep green, decommission blue
6. If FAIL: Rollback to blue
```

### Rolling Update (Docker Swarm/K8s)

```bash
# Docker Swarm
docker service update --image docker.n8n.io/n8nio/n8n:latest n8n_web

# Kubernetes
kubectl set image deployment/n8n-web n8n=docker.n8n.io/n8nio/n8n:latest
```

---

## 📈 Scaling

### Horizontal Scaling

```bash
# Add more workers
docker compose up -d --scale n8n-worker=5

# Or with Docker Swarm
docker service scale n8n-worker=5
```

### Vertical Scaling

```bash
# Increase resources in docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
    reservations:
      cpus: '2'
      memory: 4G
```

---

## ✅ Post-Deployment Verification

```
1. Access UI via HTTPS
   ✓ Login works
   ✓ Workflows visible
   ✓ Editor functional

2. Webhooks
   ✓ Test webhook URL accessible
   ✓ Production webhook working
   ✓ SSL certificate valid

3. Executions
   ✓ Manual execution works
   ✓ Trigger-based execution works
   ✓ Queue processing working

4. Integrations
   ✓ Credentials accessible
   ✓ API connections working
   ✓ External services reachable

5. Monitoring
   ✓ Logs being written
   ✓ Metrics being collected
   ✓ Alerts configured
   ✓ Backup running successfully
```

---

## 🚀 Next Steps

→ [Scaling & Performance](31-scaling-performance.md)
→ [Security & Compliance](32-security-compliance.md)
