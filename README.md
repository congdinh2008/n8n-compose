# n8n Infrastructure as Code

This repository contains the infrastructure configuration for running n8n with PostgreSQL on multiple cloud providers (AWS, Azure, and GCP) using Terraform.

## Prerequisites

### General Prerequisites
- Terraform installed
- Docker and Docker Compose (for local development)
- Domain name with DNS access

### Cloud-Specific Prerequisites
- **AWS**: AWS Account and AWS CLI configured
- **Azure**: Azure Account and Azure CLI configured
- **GCP**: GCP Account and gcloud CLI configured

## Setup Instructions

1. Clone this repository
2. Copy configuration files:
   ```bash
   cp example.env .env
   ```

3. Choose your cloud provider and navigate to the appropriate directory:

### AWS Deployment
1. Navigate to the AWS environment directory:
   ```bash
   cd terraform/aws/environments/dev
   cp terraform.example.tfvars terraform.tfvars
   ```

2. Update configuration in `terraform.tfvars` with your domain, subdomain, timezone, and SSL email
3. Generate AWS key pair named "n8n-key-pair" for SSH access or specify a different key name in your configuration
4. Deploy the infrastructure:
   ```bash
   terraform init
   terraform apply
   ```

### Azure Deployment
1. Navigate to the Azure environment directory:
   ```bash
   cd terraform/azure/environments/dev
   cp terraform.example.tfvars terraform.tfvars
   ```

2. Update configuration in `terraform.tfvars` with your domain, subdomain, timezone, and SSL email
3. Configure SSH access by providing your public key in the terraform.tfvars file
4. Deploy the infrastructure:
   ```bash
   terraform init
   terraform apply
   ```

### GCP Deployment
1. Navigate to the GCP environment directory:
   ```bash
   cd terraform/gcp/environments/dev
   cp terraform.example.tfvars terraform.tfvars
   ```

2. Update configuration in `terraform.tfvars` with your domain, subdomain, timezone, and SSL email
3. Ensure you have a GCP project created and set in your terraform.tfvars
4. Configure SSH access by providing your public key in the terraform.tfvars file
5. Deploy the infrastructure:
   ```bash
   terraform init
   terraform apply
   ```

## Infrastructure Components

### Common Components (All Cloud Providers)
- Virtual machine running n8n
- PostgreSQL database using Docker
- Nginx as reverse proxy
- Automatic SSL certificate from Let's Encrypt
- Resource constraints for containers (CPU and memory limits)
- Optional automated backups

### AWS-Specific Components
- VPC with public subnet
- EC2 instance with configurable instance type
- Optional Elastic IP allocation
- Optional CloudWatch monitoring and alarms
- Security groups limiting access to necessary ports

### Azure-Specific Components
- Virtual Network with subnet
- Virtual Machine with configurable size
- Network Security Group for access control
- Optional Public IP allocation
- Resource Group for organized resource management

### GCP-Specific Components
- VPC Network with subnet
- Compute Engine instance with configurable machine type
- Optional static IP allocation
- Firewall rules limiting access to necessary ports
- Optional Google Cloud Operations integration

## Security Features

- SSL/HTTPS enabled by default
- Firewall/Security groups limiting access to necessary ports
- Environment variables for sensitive data
- Optional basic authentication for n8n interface
- Strong encryption key for sensitive workflow data
- Local-only port binding by default
- Configurable SSH access restrictions
- Fail2ban for SSH protection

## Backup and Disaster Recovery

All cloud deployments include optional automated backup functionality that:
- Creates weekly backups of n8n data
- Stores backups locally on the VM
- Automatically rotates backups older than 7 days
- Can be enabled/disabled via the `enable_auto_backup` variable

## Local Development

For local development without cloud deployment:

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

## Configuration Parameters

### Common Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `domain_name` | Your top-level domain | Required |
| `subdomain` | Subdomain for n8n | Required |
| `ssl_email` | Email for Let's Encrypt notifications | Required |
| `db_user` | Username for PostgreSQL database | n8n |
| `db_password` | Password for PostgreSQL database | Required |
| `db_name` | Database name for PostgreSQL | n8n |
| `timezone` | Timezone for n8n | UTC |
| `n8n_protocol` | Protocol to use (http or https) | https |
| `enable_basic_auth` | Enable basic authentication | true |
| `basic_auth_user` | Username for basic authentication | admin |
| `basic_auth_password` | Password for basic authentication | Required |
| `enable_auto_backup` | Enable automated backups | true |

### AWS-Specific Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | AWS region to deploy resources | us-west-2 |
| `instance_type` | EC2 instance type | t3.small |
| `enable_elastic_ip` | Allocate Elastic IP | true |
| `ssh_key_name` | Name of SSH key pair | n8n-key-pair |
| `ssh_cidr_blocks` | CIDR blocks for SSH access | ["0.0.0.0/0"] |

### Azure-Specific Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `location` | Azure region to deploy resources | eastus |
| `vm_size` | Azure VM size | Standard_B2s |
| `admin_username` | Admin username for VM | n8n |
| `ssh_public_key` | Public SSH key content | Required |

### GCP-Specific Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | Your GCP project ID | Required |
| `region` | GCP region to deploy resources | us-central1 |
| `zone` | GCP zone to deploy the instance | us-central1-a |
| `machine_type` | Machine type for VM instance | e2-medium |
| `ssh_username` | Username for SSH access | n8n |
| `ssh_pub_key_path` | Path to the public SSH key file | Required |

## Accessing Your n8n Instance

After successful deployment, your n8n instance will be available at:

```
https://[subdomain].[domain_name]
```

If you've enabled basic authentication, you'll need to use the credentials specified in your configuration.

## Troubleshooting

If you encounter issues during deployment:

1. Check cloud provider logs:
   - **AWS**: EC2 Instance Connect or SSH into the instance and check `/var/log/n8n-setup.log`
   - **Azure**: Connect to the VM via SSH and check `/var/log/n8n-setup.log`
   - **GCP**: Connect to the VM via SSH and check `/var/log/n8n-setup.log`

2. Verify that your domain's DNS settings are correctly pointing to your cloud instance's IP address

3. Check if the required ports are open in the security groups/firewall rules (80, 443, and 22 for SSH)

4. For SSL certificate issues, ensure your domain is properly configured and accessible from the internet

## Cloud Provider Comparison

| Feature | AWS | Azure | GCP |
|---------|-----|-------|-----|
| **Region Availability** | Global | Global | Global |
| **Machine Types** | Wide range of EC2 instances | Various VM sizes | Compute Engine instance types |
| **Network Integration** | VPC, Security Groups | VNet, NSGs | VPC, Firewall Rules |
| **Monitoring** | CloudWatch | Azure Monitor | Cloud Operations |
| **Cost Optimization** | Spot Instances option | B-series VMs (burstable) | Preemptible VMs option |
| **Backup Options** | Built-in + S3 option | Built-in + Storage option | Built-in + GCS option |

## Contributing

Contributions to improve the infrastructure setup for any cloud provider are welcome. Please submit a pull request with your changes.
