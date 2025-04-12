# Project and resource identification
name_prefix = "n8n-dev"
location    = "Southeast Asia"  # Change this to your preferred Azure region
common_tags = {
  Project     = "n8n"
  Environment = "development"
  Terraform   = "true"
  Owner       = "YourName"
}

# Network configuration
vnet_cidr        = "10.0.0.0/16"
subnet_cidr      = "10.0.1.0/24"
enable_public_ip = true

# Security configuration - customize this for production!
security_rules = [
  {
    port        = "22"
    protocol    = "Tcp"
    cidr_blocks = ["YOUR_IP_ADDRESS/32"]  # Restrict to your IP only for security
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

# VM configuration
vm_size             = "Standard_B2s"  # Cost-effective for development
admin_username      = "n8nadmin"
ssh_public_key_path = "~/.ssh/id_rsa.pub"  # Path to your SSH public key
os_disk_type        = "Standard_LRS"
os_disk_size        = 30

# Image configuration - Ubuntu Server 20.04 LTS
image_publisher     = "Canonical"
image_offer         = "0001-com-ubuntu-server-focal"
image_sku           = "20_04-lts"
image_version       = "latest"

# n8n configuration
domain_name         = "example.com"
subdomain           = "n8n"
timezone            = "Asia/Ho_Chi_Minh"
ssl_email           = "your-email@example.com"
n8n_protocol        = "https"
db_user             = "n8n"
db_password         = "changeThisPassword!"  # Change this!
db_name             = "n8n"

# Optional authentication
enable_basic_auth   = true
basic_auth_user     = "admin"
basic_auth_password = "changeThisPassword!"  # Change this!

# Optional features
create_managed_identity = false
enable_backups          = false
create_monitoring       = false
log_analytics_workspace_id = ""  # Fill this if create_monitoring = true
enable_auto_backup      = true
