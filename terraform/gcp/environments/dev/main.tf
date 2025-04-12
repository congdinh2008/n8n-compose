terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
  
  # Uncomment this block to use Terraform Cloud for this workspace
  # cloud {
  #   organization = "your-organization"
  #   workspaces {
  #     name = "n8n-gcp-dev"
  #   }
  # }
}

provider "google" {
  # Using gcloud CLI authentication instead of credentials file
  # Requires running 'gcloud auth application-default login' first
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

module "n8n" {
  source = "../../modules/n8n"

  # Project configuration
  project_id  = var.project_id
  region      = var.region
  zone        = var.zone
  name_prefix = "${var.environment}-${var.name_prefix}"

  # Network configuration
  subnet_cidr        = var.subnet_cidr
  ssh_source_ranges  = var.ssh_source_ranges
  n8n_direct_access  = var.n8n_direct_access
  enable_nat         = var.enable_nat

  # VM configuration
  machine_type               = var.machine_type
  disk_image                 = var.disk_image
  disk_size_gb               = var.disk_size_gb
  disk_type                  = var.disk_type
  ssh_username               = var.ssh_username
  ssh_pub_key_path           = var.ssh_pub_key_path
  enable_static_ip           = var.enable_static_ip
  use_preemptible            = var.use_preemptible
  enable_deletion_protection = var.enable_deletion_protection
  enable_secure_boot         = var.enable_secure_boot

  # Service account configuration
  create_service_account = var.create_service_account
  service_account_email  = var.service_account_email
  service_account_roles  = var.service_account_roles

  # n8n configuration
  domain_name         = var.domain_name
  subdomain           = var.subdomain
  timezone            = var.timezone
  ssl_email           = var.ssl_email
  n8n_protocol        = var.n8n_protocol
  db_user             = var.db_user
  db_password         = var.db_password
  db_name             = var.db_name
  enable_basic_auth   = var.enable_basic_auth
  basic_auth_user     = var.basic_auth_user
  basic_auth_password = var.basic_auth_password

  # Backup configuration
  enable_auto_backup     = var.enable_auto_backup
  enable_scheduled_backups = var.enable_scheduled_backups
  backup_schedule        = var.backup_schedule

  # Tags
  common_tags            = merge(var.common_tags, {
    Environment = var.environment
    Project     = "n8n"
    Terraform   = "true"
  })
}
