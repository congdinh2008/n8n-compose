# =======================
# DOMAIN CONFIGURATION
# =======================
domain_name = "example.com"
subdomain = "n8n"
timezone = "Asia/Ho_Chi_Minh" # Set your timezone here

# =======================
# SECURITY & ACCESS
# =======================
ssl_email = "your-email@example.com"
enable_elastic_ip = false  # Set to true if you want a static IP address
key_name = "n8n-key-pair"  # Name of your SSH key pair in AWS
n8n_direct_access = false  # Whether to allow direct access to n8n port 5678 from outside
ssh_cidr_blocks = "0.0.0.0/0"  # Restrict this in production!

# =======================
# AWS CONFIGURATION
# =======================
aws_region = "ap-southeast-1"  # AWS region to deploy resources in

# =======================
# INSTANCE CONFIGURATION
# =======================
ami_id = "ami-0df7a207adb9748c7"  # Amazon Linux 2 AMI ID (adjust for your region)
instance_type = "t2.micro"
availability_zone = "ap-southeast-1a"
root_volume_size = 30
root_volume_type = "gp2"

# =======================
# NETWORK CONFIGURATION
# =======================
vpc_cidr = "10.0.0.0/16"
subnet_cidr = "10.0.1.0/24"

# =======================
# DATABASE CONFIGURATION
# =======================
db_user = "n8n"
db_password = "change_me_please"  # IMPORTANT: Change this in production!
db_name = "n8n"

# =======================
# N8N CONFIGURATION
# =======================
n8n_protocol = "https"  # http or https
enable_basic_auth = false
basic_auth_user = "admin"
basic_auth_password = "change_me_please"  # IMPORTANT: Change this if enabling basic auth

# =======================
# MONITORING & PROTECTION
# =======================
enable_detailed_monitoring = false
enable_termination_protection = false
delete_volume_on_termination = true
enable_auto_backup = false

# =======================
# ADVANCED CONFIGURATION
# =======================
create_iam_role = false
instance_profile_name = ""
create_alarms = false
alarm_actions = []
enable_backups = false
backup_role_arn = ""
backup_plan_id = ""

# =======================
# TAGGING
# =======================
common_tags = {
  Project     = "n8n"
  Environment = "development"
  Terraform   = "true"
}