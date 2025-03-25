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
