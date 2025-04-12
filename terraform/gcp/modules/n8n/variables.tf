variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "n8n"
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
}

variable "zone" {
  description = "The GCP zone to deploy the instance"
  type        = string
}

variable "machine_type" {
  description = "The machine type for the VM instance"
  type        = string
  default     = "e2-medium"
}

variable "disk_image" {
  description = "The disk image for the VM instance"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2004-lts"
}

variable "disk_size_gb" {
  description = "Size of the boot disk in GB"
  type        = number
  default     = 30
}

variable "disk_type" {
  description = "Type of the boot disk"
  type        = string
  default     = "pd-standard"
}

variable "network_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

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
  default     = "Asia/Ho_Chi_Minh"
}

variable "ssl_email" {
  description = "Email for SSL certificate"
  type        = string
}

variable "enable_static_ip" {
  description = "Whether to allocate and associate a static external IP to the instance"
  type        = bool
  default     = true
}

variable "ssh_username" {
  description = "Username for SSH access"
  type        = string
  default     = "n8n"
}

variable "ssh_pub_key_path" {
  description = "Path to the public SSH key file"
  type        = string
}

variable "ssh_source_ranges" {
  description = "CIDR blocks that are allowed to connect via SSH"
  type        = string
  default     = "0.0.0.0/0" # Restrict this in production!
}

variable "n8n_direct_access" {
  description = "Whether to allow direct access to n8n port 5678 from outside (not recommended for production)"
  type        = bool
  default     = false
}

variable "n8n_protocol" {
  description = "Protocol to use for n8n (http or https)"
  type        = string
  default     = "https"
}

variable "use_preemptible" {
  description = "Whether to use a preemptible VM instance (lower cost but may be terminated)"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Protect the instance from accidental deletion"
  type        = bool
  default     = false
}

variable "create_service_account" {
  description = "Whether to create a service account for the VM instance"
  type        = bool
  default     = true
}

variable "service_account_email" {
  description = "Email of an existing service account to use (if create_service_account is false)"
  type        = string
  default     = ""
}

variable "service_account_roles" {
  description = "List of roles to assign to the service account"
  type        = list(string)
  default     = ["roles/compute.instanceAdmin.v1", "roles/storage.objectViewer"]
}

variable "enable_secure_boot" {
  description = "Enable secure boot for the VM instance"
  type        = bool
  default     = true
}

variable "enable_nat" {
  description = "Whether to enable Cloud NAT for instances without public IPs"
  type        = bool
  default     = false
}

variable "enable_scheduled_backups" {
  description = "Whether to enable scheduled backups for the instance"
  type        = bool
  default     = false
}

variable "backup_schedule" {
  description = "Cron expression for the backup schedule"
  type        = string
  default     = "0 0 * * *" # Daily at midnight
}

variable "db_user" {
  description = "Database user for n8n"
  type        = string
  default     = "n8n"
}

variable "db_password" {
  description = "Database password for n8n"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name for n8n"
  type        = string
  default     = "n8n"
}

variable "enable_basic_auth" {
  description = "Whether to enable basic authentication for n8n"
  type        = bool
  default     = true
}

variable "basic_auth_user" {
  description = "Username for basic authentication"
  type        = string
  default     = "admin"
}

variable "basic_auth_password" {
  description = "Password for basic authentication"
  type        = string
  sensitive   = true
}

variable "enable_auto_backup" {
  description = "Whether to enable automatic backups for n8n"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    Project     = "n8n"
    Environment = "production"
    Terraform   = "true"
  }
}
