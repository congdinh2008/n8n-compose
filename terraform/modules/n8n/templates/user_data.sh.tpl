#!/bin/bash

# Load environment variables
cat > /etc/n8n.env << 'ENV'
DOMAIN_NAME=${domain_name}
SUBDOMAIN=${subdomain}
GENERIC_TIMEZONE=${timezone}
SSL_EMAIL=${ssl_email}
ENV

# Source environment variables
set -a
source /etc/n8n.env
set +a

# Install required packages
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common nginx certbot python3-certbot-nginx
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Configure Docker permissions
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# unix:///var/run/docker.sock
sudo chmod 666 /var/run/docker.sock

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create n8n directory and configuration
mkdir -p /opt/n8n
cd /opt/n8n

# Create environment file with proper values interpolated
cat > /opt/n8n/.env << EOF
DOMAIN_NAME=$DOMAIN_NAME
SUBDOMAIN=$SUBDOMAIN
GENERIC_TIMEZONE=$GENERIC_TIMEZONE
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=n8n
N8N_HOST=$DOMAIN_NAME
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://$SUBDOMAIN.$DOMAIN_NAME/
EOF

# Create docker-compose.yml without environment variable interpolation
cat > docker-compose.yml << 'COMPOSE'
services:
  postgres:
    image: postgres:15-alpine
    restart: always
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=n8n
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 5s
      timeout: 5s
      retries: 5

  n8n:
    image: docker.n8n.io/n8nio/n8n
    restart: always
    ports:
      - "127.0.0.1:5678:5678"
    env_file:
      - .env
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  postgres_data:
  n8n_data:
COMPOSE

# Set proper permissions
chown -R ubuntu:ubuntu /opt/n8n
chmod 600 /opt/n8n/.env

# Configure Nginx
cat > /etc/nginx/sites-available/n8n << EOF
server {
    server_name ${subdomain}.${domain_name};
    
    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable the Nginx site
ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Check existing SSL certificate
DOMAIN="$SUBDOMAIN.$DOMAIN_NAME"
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    # Check certificate expiration (30 days threshold)
    EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_REMAINING=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
    
    if [ $DAYS_REMAINING -gt 30 ]; then
        echo "Certificate for $DOMAIN is still valid for $DAYS_REMAINING days. Skipping renewal."
    else
        echo "Certificate for $DOMAIN will expire in $DAYS_REMAINING days. Proceeding with renewal."
        certbot renew --quiet
    fi
else
    echo "No existing certificate found for $DOMAIN. Obtaining new certificate."
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$SSL_EMAIL" --redirect
fi

# Start n8n with proper error handling
cd /opt/n8n
docker-compose pull
docker-compose down --volumes --remove-orphans
sleep 5
docker-compose up -d

# Wait for services to be healthy
attempt=1
max_attempts=30
until docker-compose ps | grep "n8n" | grep "Up" || [ $attempt -eq $max_attempts ]; do
    echo "Waiting for n8n to start (attempt $attempt/$max_attempts)..."
    sleep 10
    attempt=$(( attempt + 1 ))
done

if [ $attempt -eq $max_attempts ]; then
    echo "Failed to start n8n after $max_attempts attempts"
    docker-compose logs
    exit 1
fi

echo "n8n has started successfully"

