# n8n Infrastructure as Code

This repository contains the infrastructure configuration for running n8n with PostgreSQL on AWS using Terraform.

## Prerequisites

- AWS Account and AWS CLI configured
- Terraform installed
- Docker and Docker Compose (for local development)
- Domain name configured in Route53 (for SSL/HTTPS)

## Setup Instructions

1. Clone this repository
2. Copy configuration files:
   ```bash
   cp example.env .env
   cd terraform/environments/dev
   cp terraform.example.tfvars terraform.tfvars
   ```
3. Update configuration:
   - Edit `.env` with your domain, subdomain, timezone, and SSL email
   - Edit `terraform.tfvars` with the same values
   - Generate AWS key pair named "n8n-key-pair" for SSH access or specify a different key name in your configuration

4. Initialize and apply Terraform:
   ```bash
   cd terraform/environments/dev
   terraform init
   terraform apply
   ```

## Configuration Files

- `example.env`: Template for environment variables
- `terraform.example.tfvars`: Template for Terraform variables
- `.env`: Your actual environment configuration (not committed)
- `terraform.tfvars`: Your actual Terraform configuration (not committed)

## Infrastructure Components

- VPC with public subnet
- EC2 instance running n8n
- PostgreSQL database using Docker
- Nginx as reverse proxy
- Automatic SSL certificate from Let's Encrypt
- Resource constraints for containers (CPU and memory limits)
- Optional Elastic IP allocation
- Optional CloudWatch monitoring and alarms
- Optional automated backups

## Security

- SSL/HTTPS enabled by default
- Security groups limiting access to necessary ports
- Environment variables for sensitive data
- Optional basic authentication for n8n interface
- Strong encryption key for sensitive workflow data
- Local-only port binding by default
- Configurable SSH access restrictions

## Local Development

For local development without AWS:

1. Copy and configure .env:
   ```bash
   cp example.env .env
   ```

2. Edit the essential configuration variables in .env:
   ```
   DOMAIN_NAME=example.com
   SUBDOMAIN=n8n
   POSTGRES_PASSWORD=your_secure_password
   N8N_ENCRYPTION_KEY=your_random_encryption_key
   SSL_EMAIL=your-email@example.com
   ```

3. Start n8n locally:
   ```bash
   docker-compose up -d
   ```

4. Access n8n at http://localhost:5678

## Environment Variables

### Required Variables
- `DOMAIN_NAME`: Your top-level domain
- `SUBDOMAIN`: Subdomain for n8n (e.g., "n8n" for n8n.example.com)
- `SSL_EMAIL`: Email for Let's Encrypt notifications
- `POSTGRES_PASSWORD`: Password for PostgreSQL database (change from default!)
- `N8N_ENCRYPTION_KEY`: Encryption key for sensitive workflow data

### Optional Variables
- `GENERIC_TIMEZONE`: Timezone for n8n (default: UTC)
- `N8N_PROTOCOL`: Protocol to use (http or https, default: http)
- `N8N_PORT_MAPPING`: Port mapping for n8n service (default: 127.0.0.1:5678:5678)
- `N8N_BASIC_AUTH_ACTIVE`: Enable basic authentication (default: false)
- `N8N_BASIC_AUTH_USER`: Username for basic authentication
- `N8N_BASIC_AUTH_PASSWORD`: Password for basic authentication

### AWS Configuration
- `KEY_NAME`: SSH key pair name (default: n8n-key-pair)
- `ENABLE_ELASTIC_IP`: Allocate static IP (default: false)
- `AWS_REGION`: AWS region for deployment (default: ap-southeast-1)
- `INSTANCE_TYPE`: EC2 instance type (default: t2.micro)
- `ROOT_VOLUME_SIZE`: Root volume size in GB (default: 30)
- `SSH_CIDR_BLOCKS`: IP ranges allowed to connect via SSH
- `ENABLE_AUTO_BACKUP`: Enable weekly automated backups (default: false)
- `ENABLE_DETAILED_MONITORING`: Enable CloudWatch detailed monitoring
- `ENABLE_TERMINATION_PROTECTION`: Protect instance from accidental termination

## Resource Management

The Docker Compose configuration includes resource limits for containers:
- PostgreSQL: 1 CPU, 1GB memory
- n8n: 1 CPU, 1GB memory

Adjust these limits in the docker-compose.yml file according to your needs.

## Backup and Recovery

When `ENABLE_AUTO_BACKUP` is set to true, the system will:
- Create weekly backups of n8n data
- Store backups in the configured AWS region
- Retain backups according to AWS Backup settings

For manual backups of your local environment, you can use Docker volume backup procedures.
