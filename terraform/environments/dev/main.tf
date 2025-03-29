provider "aws" {
  region = var.aws_region
}

locals {
  environment = "development"
  name_prefix = "n8n-${local.environment}"
}

module "n8n" {
  source = "../../modules/n8n"

  # Cấu hình cơ bản
  name_prefix       = local.name_prefix
  vpc_cidr          = var.vpc_cidr
  subnet_cidr       = var.subnet_cidr
  availability_zone = var.availability_zone
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_name

  # Cấu hình ổ đĩa
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type
  delete_volume_on_termination = var.delete_volume_on_termination

  # Cấu hình domain và SSL
  domain_name = var.domain_name
  subdomain   = var.subdomain
  timezone    = var.timezone
  ssl_email   = var.ssl_email
  n8n_protocol = var.n8n_protocol
  
  # Cấu hình bảo mật
  enable_basic_auth = var.enable_basic_auth
  basic_auth_user = var.basic_auth_user
  basic_auth_password = var.basic_auth_password
  ssh_cidr_blocks = var.ssh_cidr_blocks
  n8n_direct_access = var.n8n_direct_access
  
  # Cấu hình Database
  db_user = var.db_user
  db_password = var.db_password
  db_name = var.db_name
  
  # Cấu hình IP và backup
  enable_elastic_ip = var.enable_elastic_ip
  enable_auto_backup = var.enable_auto_backup

  # Cấu hình monitoring và bảo vệ
  enable_detailed_monitoring = var.enable_detailed_monitoring
  enable_termination_protection = var.enable_termination_protection
  
  # Tags
  common_tags = var.common_tags
}
