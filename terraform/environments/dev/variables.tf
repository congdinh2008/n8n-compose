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

variable "enable_elastic_ip" {
  description = "Whether to allocate and associate an Elastic IP to the instance"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the EC2 instance"
  type        = string
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

# EC2 Instance Variables
variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type for EC2 instance"
  type        = string
  default     = "t3.small"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp2"
}

# Network Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "n8n_direct_access" {
  description = "Whether to allow direct access to n8n port 5678 from outside"
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks that are allowed to connect via SSH"
  type        = string
  default     = "0.0.0.0/0"
}

# Database Configuration
variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "n8n"
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
  default     = "n8n"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "n8n"
}

# Security Configuration
variable "n8n_protocol" {
  description = "Protocol to use for n8n (http or https)"
  type        = string
  default     = "https"
}

variable "enable_basic_auth" {
  description = "Whether to enable HTTP Basic Authentication for n8n"
  type        = bool
  default     = false
}

variable "basic_auth_user" {
  description = "Username for HTTP Basic Authentication"
  type        = string
  default     = "admin"
}

variable "basic_auth_password" {
  description = "Password for HTTP Basic Authentication"
  type        = string
  sensitive   = true
  default     = ""
}

# Monitoring and Protection
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for the instance"
  type        = bool
  default     = false
}

variable "enable_termination_protection" {
  description = "Protect the instance from accidental termination"
  type        = bool
  default     = false
}

variable "delete_volume_on_termination" {
  description = "Whether to delete the EBS volume when the instance is terminated"
  type        = bool
  default     = true
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "n8n"
    Environment = "development"
    Terraform   = "true"
  }
}