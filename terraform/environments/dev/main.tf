provider "aws" {
  region = "ap-southeast-1"  # Singapore region
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
  availability_zone = "ap-southeast-1a"
  ami_id           = "ami-078c1149d8ad719a7"  # Ubuntu 22.04 LTS in ap-southeast-1
  instance_type    = "t2.micro"
  key_name         = "n8n-key-pair"

  # Variables from .env file
  domain_name = var.domain_name
  subdomain   = var.subdomain
  timezone    = var.timezone
  ssl_email   = var.ssl_email

  root_volume_size = 30
  root_volume_type = "gp2"

  common_tags = {
    Project     = "n8n"
    Environment = local.environment
    Terraform   = "true"
    Owner       = "DevOps"
  }
}
