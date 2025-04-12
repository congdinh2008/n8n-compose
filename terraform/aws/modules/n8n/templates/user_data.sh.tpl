#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail
IFS=$'\n\t'

# Define logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/n8n-setup.log
}

log "Starting n8n setup script"

# Install required packages
log "Installing required packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common nginx certbot python3-certbot-nginx fail2ban ufw jq unzip

# Configure fail2ban for SSH protection
log "Configuring fail2ban for SSH protection"
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
findtime = 300
bantime = 3600
EOF
systemctl restart fail2ban

# Configure UFW (Uncomplicated Firewall)
log "Configuring firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 5678/tcp comment 'n8n access'
echo "y" | ufw enable

# Install Docker with proper key management (updated method)
log "Installing Docker"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Configure Docker permissions and start service
log "Configuring Docker"
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# Install Docker Compose v2
log "Installing Docker Compose"
DOCKER_COMPOSE_VERSION="2.23.0"
curl -L "https://github.com/docker/compose/releases/download/v$${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create n8n directory structure
log "Creating n8n directory structure"
mkdir -p /opt/n8n/nginx
mkdir -p /opt/n8n/logs
mkdir -p /opt/n8n/src
cd /opt/n8n

# Setup backup functionality if enabled
if [ "${enable_auto_backup}" = "true" ]; then
  log "Setting up automated backup functionality"
  mkdir -p /opt/n8n/backups
  
  # Create backup script
  cat > /opt/n8n/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/n8n/backups"
BACKUP_FILE="n8n-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Stop n8n service
cd /opt/n8n/src
docker-compose stop n8n

# Create backup
tar -czf $BACKUP_DIR/$BACKUP_FILE -C /opt/n8n .

# Start n8n service
docker-compose start n8n

# Remove backups older than 7 days
find $BACKUP_DIR -type f -name "n8n-backup-*.tar.gz" -mtime +7 -delete

# Log backup
echo "Backup completed: $BACKUP_FILE" >> /var/log/n8n-backup.log
EOF
  chmod +x /opt/n8n/backup.sh
  
  # Create backup service and timer
  cat > /etc/systemd/system/n8n-backup.service << EOT
[Unit]
Description=n8n Backup Service

[Service]
Type=oneshot
ExecStart=/opt/n8n/backup.sh
EOT

  cat > /etc/systemd/system/n8n-backup.timer << EOT
[Unit]
Description=Weekly n8n backup

[Timer]
OnCalendar=Sun 01:00:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOT
fi

# Create docker-compose.yml file directly instead of cloning from GitHub
log "Creating docker-compose.yml file"
cat > /opt/n8n/src/docker-compose.yml << EOT
services:
  postgres:
    image: postgres:latest
    restart: always
    environment:
      - POSTGRES_USER=${db_user}
      - POSTGRES_PASSWORD=${db_password}
      - POSTGRES_DB=${db_name}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${db_user}"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - n8n-network
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    restart: always
    ports:
      - "127.0.0.1:5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${db_name}
      - DB_POSTGRESDB_USER=${db_user}
      - DB_POSTGRESDB_PASSWORD=${db_password}
      - N8N_HOST=${subdomain}.${domain_name}
      - N8N_PORT=5678
      - N8N_PROTOCOL=${n8n_protocol}
      - NODE_ENV=production
      - WEBHOOK_URL=${n8n_protocol}://${subdomain}.${domain_name}/
      - GENERIC_TIMEZONE=${timezone}
      - N8N_ENCRYPTION_KEY=$(openssl rand -hex 24)
      - N8N_BASIC_AUTH_ACTIVE=${enable_basic_auth}
      - N8N_BASIC_AUTH_USER=${basic_auth_user}
      - N8N_BASIC_AUTH_PASSWORD=${basic_auth_password}
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - n8n-network
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

networks:
  n8n-network:
    driver: bridge

volumes:
  postgres_data:
    name: n8n_postgres_data
  n8n_data:
    name: n8n_n8n_data
EOT

# Process nginx configuration file
log "Configuring Nginx"
cat > /etc/nginx/sites-available/n8n << EOT
# Optimized n8n nginx configuration
server {
    server_name ${subdomain}.${domain_name};
    
    access_log /var/log/nginx/n8n-access.log;
    error_log /var/log/nginx/n8n-error.log;
    
    # Security headers
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval';" always;
    
    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Allow large file uploads
    client_max_body_size 100M;
    
    # Compression settings
    gzip on;
    gzip_comp_level 5;
    gzip_min_length 256;
    gzip_proxied any;
    gzip_vary on;
    gzip_types
        application/javascript
        application/json
        application/x-javascript
        application/xml
        application/xml+rss
        text/css
        text/javascript
        text/plain
        text/xml;
}
EOT

# Setup nginx
ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Set up Let's Encrypt SSL certificate
log "Setting up SSL certificate"
log "Checking SSL certificate for ${subdomain}.${domain_name}"

# Check existing SSL certificate
DOMAIN="${subdomain}.${domain_name}"
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    # Check certificate expiration (30 days threshold)
    EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_REMAINING=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
    
    if [ $DAYS_REMAINING -gt 30 ]; then
        log "Certificate for $DOMAIN is still valid for $DAYS_REMAINING days. Skipping renewal."
    else
        log "Certificate for $DOMAIN will expire in $DAYS_REMAINING days. Proceeding with renewal."
        certbot renew --quiet
    fi
else
    log "No existing certificate found for $DOMAIN. Obtaining new certificate."
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "${ssl_email}" --redirect
fi

# Make sure docker socket is accessible
log "Setting Docker permissions"
sudo chmod 666 /var/run/docker.sock

# Start n8n with proper error handling
log "Starting n8n"
cd /opt/n8n/src
docker-compose pull
docker-compose down --volumes --remove-orphans 2>/dev/null || true
sleep 5
docker-compose up -d

