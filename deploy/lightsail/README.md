# Deploy n8n on AWS Lightsail

This deployment targets one shared classroom host at `n8n.mochiai.vn`:

- AWS Lightsail `medium_3_0`, Singapore, Ubuntu 24.04 LTS
- 2 vCPU, 4 GB RAM, 80 GB SSD
- n8n 2.37.9, PostgreSQL 17, Caddy 2.11.4
- HTTPS on ports 80 and 443; SSH on port 22
- n8n port 5678 bound to the instance loopback address only
- three concurrent production executions as an initial classroom limit
- daily local application backup with seven-day retention
- Lightsail automatic snapshots managed separately in AWS

## Deploy

Create the Lightsail instance with `prepare-host.sh` as its launch script. Attach a static IP and restrict SSH to the administrator's public IP.

Copy this directory to the instance, then run:

```bash
sudo N8N_HOST=n8n.mochiai.vn \
  SSL_EMAIL=YOUR_CERTIFICATE_EMAIL \
  bash ./install.sh
```

The installer generates a unique PostgreSQL password and n8n encryption key in `/opt/n8n/.env`. It refuses to overwrite an existing environment.

Before exposing the domain, create the n8n owner through an SSH tunnel:

```bash
ssh -L 15678:127.0.0.1:5678 ubuntu@LIGHTSAIL_STATIC_IP
```

Open `http://localhost:15678`, create the owner, then point the DNS A record to the static IP and start Caddy:

```bash
cd /opt/n8n
sudo docker compose up -d caddy
```

Verify:

```bash
sudo docker compose ps
curl -fsS https://n8n.mochiai.vn/healthz
sudo systemctl status n8n-backup.timer --no-pager
```

Do not expose ports 5432 or 5678 in the Lightsail firewall. Do not commit `/opt/n8n/.env`, backups, credentials, or exported workflows containing secrets.

## Operations

Start or apply the current configuration:

```bash
cd /opt/n8n
sudo docker compose up -d
```

View status and logs:

```bash
sudo docker compose ps
sudo docker compose logs --tail 100 n8n
sudo docker compose logs --tail 100 caddy
```

Run an application backup immediately:

```bash
sudo systemctl start n8n-backup.service
sudo ls -lh /opt/n8n/backups
```

The backup directory is on the instance disk. Keep Lightsail automatic snapshots enabled and test restoration before relying on the host for a class.
