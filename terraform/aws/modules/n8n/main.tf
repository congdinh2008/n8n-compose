terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

# EC2 Instance with enhanced configuration
resource "aws_instance" "n8n" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.n8n_subnet.id
  vpc_security_group_ids = [aws_security_group.n8n_sg.id]
  key_name               = var.key_name
  
  # Enable detailed monitoring (optional - costs extra)
  monitoring             = var.enable_detailed_monitoring
  
  # IAM instance profile for EC2 if needed
  iam_instance_profile   = var.create_iam_role ? aws_iam_instance_profile.n8n_profile[0].name : var.instance_profile_name
  
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
    
    # Enable deletion protection if needed
    delete_on_termination = var.delete_volume_on_termination
    
    tags = merge(var.common_tags, {
      Name = "${var.name_prefix}-root-volume"
    })
  }

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    domain_name = var.domain_name
    subdomain   = var.subdomain
    timezone    = var.timezone
    ssl_email   = var.ssl_email
    n8n_protocol = var.n8n_protocol
    db_user     = var.db_user
    db_password = var.db_password
    db_name     = var.db_name
    enable_basic_auth = var.enable_basic_auth
    basic_auth_user = var.basic_auth_user
    basic_auth_password = var.basic_auth_password
    enable_auto_backup = var.enable_auto_backup
  })
  
  metadata_options {
    http_tokens = "required" # IMDSv2 enforcement for better security
    http_endpoint = "enabled"
  }
  
  # Enable termination protection for production instances
  disable_api_termination = var.enable_termination_protection
  
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-instance"
  })
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to tags that might be added by other processes
      tags["LastBackup"],
      tags["AutoUpdate"],
    ]
  }
}

# Elastic IP (Optional)
resource "aws_eip" "n8n" {
  count    = var.enable_elastic_ip ? 1 : 0
  domain   = "vpc"
  
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-eip"
  })
}

# Elastic IP Association (Optional)
resource "aws_eip_association" "n8n" {
  count         = var.enable_elastic_ip ? 1 : 0
  instance_id   = aws_instance.n8n.id
  allocation_id = aws_eip.n8n[0].id
}

# IAM Role and Instance Profile (Optional)
resource "aws_iam_role" "n8n_role" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.name_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
  
  tags = var.common_tags
}

resource "aws_iam_instance_profile" "n8n_profile" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.name_prefix}-instance-profile"
  role  = aws_iam_role.n8n_role[0].name
}

# Optional CloudWatch Alarm for instance monitoring
resource "aws_cloudwatch_metric_alarm" "n8n_cpu_alarm" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.name_prefix}-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  
  dimensions = {
    InstanceId = aws_instance.n8n.id
  }
  
  tags = var.common_tags
}

# Automatic Backup (Optional)
resource "aws_backup_selection" "n8n_backup" {
  count        = var.enable_backups ? 1 : 0
  name         = "${var.name_prefix}-backup-selection"
  iam_role_arn = var.backup_role_arn
  plan_id      = var.backup_plan_id

  resources = [
    aws_instance.n8n.arn
  ]
  
  condition {
    string_equals {
      key   = "aws:ResourceTag/Backup"
      value = "true"
    }
  }
}
