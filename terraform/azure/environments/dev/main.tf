terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}

module "n8n" {
  source = "../../modules/n8n"

  # Project identification
  name_prefix = var.name_prefix
  location    = var.location
  common_tags = var.common_tags

  # Network settings
  vnet_cidr        = var.vnet_cidr
  subnet_cidr      = var.subnet_cidr
  enable_public_ip = var.enable_public_ip
  security_rules   = var.security_rules

  # VM configuration
  vm_size              = var.vm_size
  admin_username       = var.admin_username
  ssh_public_key_path  = var.ssh_public_key_path
  os_disk_type         = var.os_disk_type
  os_disk_size         = var.os_disk_size
  image_publisher      = var.image_publisher
  image_offer          = var.image_offer
  image_sku            = var.image_sku
  image_version        = var.image_version
  use_spot_instance    = var.use_spot_instance
  spot_max_price       = var.spot_max_price
  spot_eviction_policy = var.spot_eviction_policy

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

  # Optional features
  create_managed_identity    = var.create_managed_identity
  enable_backups             = var.enable_backups
  create_monitoring          = var.create_monitoring
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enable_auto_backup         = var.enable_auto_backup
}
