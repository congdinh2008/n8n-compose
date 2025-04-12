# GCP Project Configuration
project_id        = "your-gcp-project-id"
region            = "us-central1"
zone              = "us-central1-a"

# Environment Information
environment       = "dev"
name_prefix       = "n8n"

# Network Configuration
subnet_cidr       = "10.0.1.0/24"
ssh_source_ranges = "0.0.0.0/0"  # For production, limit this to your IP or VPN range
n8n_direct_access = false
enable_nat        = false

# VM Configuration
machine_type               = "e2-medium"
disk_image                 = "ubuntu-os-cloud/ubuntu-2004-lts"
disk_size_gb               = 30
disk_type                  = "pd-standard"
ssh_username               = "n8n"
ssh_pub_key_path           = "~/.ssh/id_rsa.pub"
enable_static_ip           = true
use_preemptible            = false
enable_deletion_protection = false
enable_secure_boot         = true

# Service Account Configuration
create_service_account = true
# service_account_email  = ""  # Use this if you have an existing service account
service_account_roles  = [
  "roles/compute.instanceAdmin.v1",
  "roles/storage.objectViewer"
]

# n8n Configuration
domain_name         = "example.com"
subdomain           = "n8n"
timezone            = "UTC"
ssl_email           = "your-email@example.com"
n8n_protocol        = "https"
db_user             = "n8n"
db_password         = "change-me-to-a-secure-password"
db_name             = "n8n"
enable_basic_auth   = true
basic_auth_user     = "admin"
basic_auth_password = "change-me-to-a-secure-password"

# Backup Configuration
enable_auto_backup      = true
enable_scheduled_backups = true
backup_schedule         = "0 0 * * *"  # Daily at midnight

# Common Tags
common_tags = {
  Project     = "n8n"
  Environment = "development"
  Terraform   = "true"
  Owner       = "your-name"
}
