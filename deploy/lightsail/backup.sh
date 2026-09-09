#!/usr/bin/env bash
set -Eeuo pipefail

install_dir=/opt/n8n
backup_dir=/opt/n8n/backups
timestamp=$(date -u +%Y%m%dT%H%M%SZ)

cd "$install_dir"
set -a
source ./.env
set +a

install -d -m 0700 "$backup_dir"

restart_n8n() {
  docker compose start n8n >/dev/null
}
trap restart_n8n EXIT

docker compose stop n8n >/dev/null
docker compose exec -T postgres pg_dump \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  --format custom > "$backup_dir/postgres-$timestamp.dump"

docker run --rm \
  --volume "${COMPOSE_PROJECT_NAME}_n8n_data:/source:ro" \
  --volume "$backup_dir:/backup" \
  alpine:3.22 \
  tar -C /source -czf "/backup/n8n-data-$timestamp.tgz" .

cp .env "$backup_dir/environment-$timestamp.env"
chmod 0600 "$backup_dir"/*
find "$backup_dir" -type f -mtime +7 -delete
