variable "domain_name" {
  description = "Domain name for n8n"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for n8n"
  type        = string
}

variable "timezone" {
  description = "Timezone for n8n"
  type        = string
}

variable "ssl_email" {
  description = "Email for SSL certificate"
  type        = string
}

variable "enable_elastic_ip" {
  description = "Whether to allocate and associate an Elastic IP to the instance"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the EC2 instance"
  type        = string
  default     = "n8n-key-pair"
}

variable "enable_auto_backup" {
  description = "Whether to enable automatic backups of n8n"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "ap-southeast-1"
}