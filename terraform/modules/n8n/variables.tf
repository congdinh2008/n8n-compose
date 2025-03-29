variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "n8n"
}

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

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type for EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
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

variable "security_group_rules" {
  description = "List of security group rules"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH access"
    },
    {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    },
    {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    },
    {
      port        = 5678
      protocol    = "tcp"
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
    Environment = "production"
    Terraform   = "true"
  }
}

variable "enable_elastic_ip" {
  description = "Whether to allocate and associate an Elastic IP to the instance"
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks that are allowed to connect via SSH"
  type        = string
  default     = "0.0.0.0/0" # Restrict this in production!
}

variable "n8n_direct_access" {
  description = "Whether to allow direct access to n8n port 5678 from outside (not recommended for production)"
  type        = bool
  default     = false
}

# New variables for enhanced configuration
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for the instance (additional charges apply)"
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Whether to create an IAM role for the EC2 instance"
  type        = bool
  default     = false
}

variable "instance_profile_name" {
  description = "Name of an existing instance profile to use (if create_iam_role is false)"
  type        = string
  default     = ""
}

variable "n8n_protocol" {
  description = "Protocol to use for n8n (http or https)"
  type        = string
  default     = "https"
}

variable "delete_volume_on_termination" {
  description = "Whether to delete the EBS volume when the instance is terminated"
  type        = bool
  default     = true
}

variable "enable_termination_protection" {
  description = "Protect the instance from accidental termination"
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms for the instance"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of ARNs to trigger when the alarm transitions to ALARM state"
  type        = list(string)
  default     = []
}

variable "enable_backups" {
  description = "Whether to enable AWS Backup for the instance"
  type        = bool
  default     = false
}

variable "backup_role_arn" {
  description = "IAM role ARN to use for AWS Backup"
  type        = string
  default     = ""
}

variable "backup_plan_id" {
  description = "AWS Backup plan ID to use"
  type        = string
  default     = ""
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "n8n"
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  default     = "n8n"
  sensitive   = true
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "n8n"
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
  default     = ""
  sensitive   = true
}

variable "enable_auto_backup" {
  description = "Whether to enable automatic backups of n8n"
  type        = bool
  default     = false
}
