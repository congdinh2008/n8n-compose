#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

: "${N8N_HOST:?Set N8N_HOST before running this script}"
: "${SSL_EMAIL:?Set SSL_EMAIL before running this script}"

source_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
install_dir=/opt/n8n

install -d -o root -g docker -m 0770 "$install_dir"
install -o root -g docker -m 0640 "$source_dir/compose.yaml" "$install_dir/compose.yaml"
install -o root -g docker -m 0640 "$source_dir/Caddyfile" "$install_dir/Caddyfile"
install -o root -g docker -m 0750 "$source_dir/backup.sh" "$install_dir/backup.sh"

if [[ -e "$install_dir/.env" ]]; then
  echo "Refusing to replace existing $install_dir/.env" >&2
  exit 1
fi

umask 077
postgres_password=$(openssl rand -hex 32)
encryption_key=$(openssl rand -hex 32)
cat > "$install_dir/.env" <<EOF
COMPOSE_PROJECT_NAME=mochiai-n8n
N8N_HOST=$N8N_HOST
SSL_EMAIL=$SSL_EMAIL
POSTGRES_USER=n8n
POSTGRES_DB=n8n
POSTGRES_PASSWORD=$postgres_password
N8N_ENCRYPTION_KEY=$encryption_key
EOF
chown root:docker "$install_dir/.env"
chmod 0640 "$install_dir/.env"

cd "$install_dir"
docker compose config --quiet
docker compose pull
docker compose up -d postgres n8n

install -o root -g root -m 0644 "$source_dir/systemd/n8n-backup.service" /etc/systemd/system/n8n-backup.service
install -o root -g root -m 0644 "$source_dir/systemd/n8n-backup.timer" /etc/systemd/system/n8n-backup.timer
systemctl daemon-reload
systemctl enable --now n8n-backup.timer

echo "n8n and PostgreSQL are running on 127.0.0.1:5678."
echo "Create the owner account through an SSH tunnel, then run:"
echo "  cd /opt/n8n && docker compose up -d caddy"
