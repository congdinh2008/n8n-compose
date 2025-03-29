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
apt-get install -y apt-transport-https ca-certificates curl software-properties-common nginx certbot python3-certbot-nginx git fail2ban ufw jq unzip

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
cd /opt/n8n
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

# Clone the GitHub repository
log "Cloning n8n repository"
git clone https://github.com/congdinh2008/n8n-compose.git .

# Create .env file with proper configuration
log "Creating environment configuration"
cat > /opt/n8n/.env << EOT
# =======================
# DOMAIN CONFIGURATION
# =======================
DOMAIN_NAME=${domain_name}
SUBDOMAIN=${subdomain}
N8N_PROTOCOL=${n8n_protocol}
N8N_PORT_MAPPING=127.0.0.1:5678:5678

# =======================
# DATABASE CONFIGURATION
# =======================
POSTGRES_USER=${db_user}
POSTGRES_PASSWORD=${db_password}
POSTGRES_DB=${db_name}

# =======================
# N8N CONFIGURATION
# =======================
GENERIC_TIMEZONE=${timezone}

# Security settings
N8N_ENCRYPTION_KEY=$(openssl rand -hex 24)
N8N_BASIC_AUTH_ACTIVE=${enable_basic_auth}
N8N_BASIC_AUTH_USER=${basic_auth_user}
N8N_BASIC_AUTH_PASSWORD=${basic_auth_password}

# =======================
# SSL CONFIGURATION
# =======================
SSL_EMAIL=${ssl_email}

# =======================
# COMPOSE PROJECT SETTINGS
# =======================
COMPOSE_PROJECT_NAME=n8n
EOT

# Source environment variables
set -a
source /opt/n8n/.env
set +a

# Process nginx configuration file
log "Configuring Nginx"
cat > /etc/nginx/sites-available/n8n << EOT
# Optimized n8n nginx configuration
server {
    server_name $SUBDOMAIN.$DOMAIN_NAME;
    
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
certbot --nginx -d "$SUBDOMAIN.$DOMAIN_NAME" --non-interactive --agree-tos --email "$SSL_EMAIL" --redirect

# Make sure docker socket is accessible
log "Setting Docker permissions"
sudo chmod 666 /var/run/docker.sock

# Start n8n with proper error handling
log "Starting n8n"
cd /opt/n8n
docker-compose pull
docker-compose down --volumes --remove-orphans 2>/dev/null || true
sleep 5
docker-compose up -d

# Wait for services to be healthy
log "Waiting for services to become healthy"
attempt=1
max_attempts=30
until docker-compose ps | grep "n8n" | grep "Up" || [ $attempt -eq $max_attempts ]; do
    log "Waiting for n8n to start (attempt $attempt/$max_attempts)..."
    sleep 10
    attempt=$(( attempt + 1 ))
done

if [ $attempt -eq $max_attempts ]; then
    log "Failed to start n8n after $max_attempts attempts"
    docker-compose logs > /opt/n8n/logs/startup_failure.log
    exit 1
else
    log "n8n has started successfully"
    log "You can access n8n at: https://$SUBDOMAIN.$DOMAIN_NAME"
fi

# Create a service to check and renew SSL certificates
log "Setting up SSL certificate auto-renewal"
cat > /etc/systemd/system/certbot-renew.service << EOT
[Unit]
Description=Certbot Renewal Service

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --nginx --post-hook "systemctl reload nginx"
EOT

cat > /etc/systemd/system/certbot-renew.timer << EOT
[Unit]
Description=Timer for Certbot Renewal

[Timer]
OnCalendar=*-*-* 00:00:00
RandomizedDelaySec=43200
Persistent=true

[Install]
WantedBy=timers.target
EOT

# Create a system health check script
log "Creating system health monitoring"
cat > /opt/n8n/healthcheck.sh << 'EOF'
#!/bin/bash
LOGFILE="/opt/n8n/logs/healthcheck.log"

echo "$(date): Running health check" >> $LOGFILE

# Check if Docker is running
if ! systemctl is-active --quiet docker; then
    echo "$(date): Docker is not running, attempting to restart" >> $LOGFILE
    systemctl restart docker
    sleep 10
fi

# Check if n8n containers are running
if ! docker ps | grep -q "n8n"; then
    echo "$(date): n8n container not running, attempting to restart" >> $LOGFILE
    cd /opt/n8n
    docker-compose up -d
fi

# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
if [ "$DISK_USAGE" -ge 90 ]; then
    echo "$(date): Disk usage is high: $DISK_USAGE%" >> $LOGFILE
fi
EOF
chmod +x /opt/n8n/healthcheck.sh

# Create a service for the healthcheck
cat > /etc/systemd/system/n8n-healthcheck.service << EOT
[Unit]
Description=n8n Health Check Service

[Service]
Type=oneshot
ExecStart=/opt/n8n/healthcheck.sh
EOT

cat > /etc/systemd/system/n8n-healthcheck.timer << EOT
[Unit]
Description=Regular n8n health check

[Timer]
OnCalendar=*-*-* *:15:00
RandomizedDelaySec=60
Persistent=true

[Install]
WantedBy=timers.target
EOT

# Enable all systemd services and timers
log "Enabling system services"
systemctl enable certbot-renew.timer
systemctl start certbot-renew.timer

if [ "${enable_auto_backup}" = "true" ]; then
  systemctl enable n8n-backup.timer
  systemctl start n8n-backup.timer
fi

systemctl enable n8n-healthcheck.timer
systemctl start n8n-healthcheck.timer

# Setup log rotation
log "Setting up log rotation"
cat > /etc/logrotate.d/n8n << EOF
/opt/n8n/logs/*.log {
    weekly
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root root
}
EOF

# Final security settings
log "Applying final security settings"

# Disable root login via ssh
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Setup unattended security upgrades
apt-get install -y unattended-upgrades apt-listchanges
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

log "Setup completed successfully"

