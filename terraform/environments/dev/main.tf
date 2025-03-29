provider "aws" {
  region = var.aws_region
}

locals {
  environment = "development"
  name_prefix = "n8n-${local.environment}"
}

module "n8n" {
  source = "../../modules/n8n"

  name_prefix       = local.name_prefix
  vpc_cidr         = "10.0.0.0/16"
  subnet_cidr      = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  ami_id           = "ami-078c1149d8ad719a7"  # Ubuntu 22.04 LTS in ap-southeast-1
  instance_type    = "t2.micro"
  key_name         = var.key_name

  # Variables from .env file
  domain_name = var.domain_name
  subdomain   = var.subdomain
  timezone    = var.timezone
  ssl_email   = var.ssl_email
  
  # Elastic IP configuration
  enable_elastic_ip = var.enable_elastic_ip
  
  # Auto backup configuration
  enable_auto_backup = var.enable_auto_backup

  root_volume_size = 30
  root_volume_type = "gp2"

  common_tags = {
    Project     = "n8n"
    Environment = local.environment
    Terraform   = "true"
    Owner       = "DevOps"
  }
}
