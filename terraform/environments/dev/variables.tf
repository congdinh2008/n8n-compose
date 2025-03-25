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