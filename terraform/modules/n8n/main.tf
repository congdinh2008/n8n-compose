terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# EC2 Instance
resource "aws_instance" "n8n" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.n8n_subnet.id
  vpc_security_group_ids = [aws_security_group.n8n_sg.id]
  key_name      = var.key_name

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    domain_name = var.domain_name
    subdomain   = var.subdomain
    timezone    = var.timezone
    ssl_email   = var.ssl_email
  })

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-instance"
  })
}
