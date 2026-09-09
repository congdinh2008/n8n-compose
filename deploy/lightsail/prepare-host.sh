#!/bin/sh
set -eu

exec >> /var/log/n8n-bootstrap.log 2>&1

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y docker.io docker-compose-v2 fail2ban ufw

systemctl enable --now docker
systemctl enable --now fail2ban
usermod -aG docker ubuntu

ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp
ufw --force enable

install -d -o root -g docker -m 0770 /opt/n8n

printf '%s\n' "Host preparation completed at $(date --iso-8601=seconds)" > /var/lib/n8n-host-ready
