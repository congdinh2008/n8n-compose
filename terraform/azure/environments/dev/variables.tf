variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "n8n-dev"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "vnet_cidr" {
  description = "CIDR block for Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "security_rules" {
  description = "List of security group rules"
  type = list(object({
    port        = string
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      port        = "22"
      protocol    = "Tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH access"
    },
    {
      port        = "80"
      protocol    = "Tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    },
    {
      port        = "443"
      protocol    = "Tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    },
    {
      port        = "5678"
      protocol    = "Tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "n8n webhook access"
    }
  ]
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "n8n"
    Environment = "development"
    Terraform   = "true"
  }
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "use_spot_instance" {
  description = "Whether to use a spot instance for cost savings"
  type        = bool
  default     = false
}

variable "spot_max_price" {
  description = "Maximum price for the spot instance"
  type        = number
  default     = -1
}

variable "spot_eviction_policy" {
  description = "Eviction policy for the spot instance"
  type        = string
  default     = "Deallocate"
  validation {
    condition     = contains(["Deallocate", "Delete"], var.spot_eviction_policy)
    error_message = "Eviction policy must be either 'Deallocate' or 'Delete'."
  }
}

variable "admin_username" {
  description = "Username for the VM admin account"
  type        = string
  default     = "n8nadmin"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
}

variable "os_disk_type" {
  description = "Type of the OS disk"
  type        = string
  default     = "Standard_LRS"
}

variable "os_disk_size" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 30
}

variable "enable_public_ip" {
  description = "Whether to allocate a public IP address to the VM"
  type        = bool
  default     = true
}

variable "image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "0001-com-ubuntu-server-focal"
}

variable "image_sku" {
  description = "SKU of the VM image"
  type        = string
  default     = "20_04-lts"
}

variable "image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
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

variable "n8n_protocol" {
  description = "Protocol to use for n8n (http or https)"
  type        = string
  default     = "https"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "n8n"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "n8n"
}

variable "enable_basic_auth" {
  description = "Whether to enable basic authentication for n8n"
  type        = bool
  default     = false
}

variable "basic_auth_user" {
  description = "Username for basic authentication"
  type        = string
  default     = ""
}

variable "basic_auth_password" {
  description = "Password for basic authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "create_managed_identity" {
  description = "Whether to create a system-assigned managed identity for the VM"
  type        = bool
  default     = false
}

variable "enable_backups" {
  description = "Whether to enable Azure Backup for the VM"
  type        = bool
  default     = false
}

variable "create_monitoring" {
  description = "Whether to create Azure Monitor diagnostic settings"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "ID of an existing Log Analytics workspace for diagnostics"
  type        = string
  default     = ""
}

variable "enable_auto_backup" {
  description = "Whether to enable automatic backups of n8n data"
  type        = bool
  default     = false
}
