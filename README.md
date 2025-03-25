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
   - Generate AWS key pair named "n8n-key-pair" for SSH access

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

## Security

- SSL/HTTPS enabled by default
- Security groups limiting access to necessary ports
- Environment variables for sensitive data

## Local Development

For local development without AWS:

1. Copy and configure .env:
   ```bash
   cp example.env .env
   ```

2. Start n8n locally:
   ```bash
   docker-compose up -d
   ```

3. Access n8n at http://localhost:5678

## Environment Variables

### Required Variables
- `DOMAIN_NAME`: Your top-level domain
- `SUBDOMAIN`: Subdomain for n8n (e.g., "n8n" for n8n.example.com)
- `SSL_EMAIL`: Email for Let's Encrypt notifications

### Optional Variables
- `GENERIC_TIMEZONE`: Timezone for n8n (default: UTC)
