# n8n-compose

Docker Compose configuration for running n8n with PostgreSQL.

## Prerequisites

- Docker
- Docker Compose

## Usage

1. Clone this repository
2. Run `docker-compose up -d`
3. Access n8n at http://localhost:5678

## Environment Variables

All configuration is done through environment variables in the docker-compose.yml file.

### PostgreSQL
- POSTGRES_USER=n8n
- POSTGRES_PASSWORD=n8n
- POSTGRES_DB=n8n

### n8n
- N8N_HOST=localhost
- N8N_PORT=5678
- N8N_PROTOCOL=http
