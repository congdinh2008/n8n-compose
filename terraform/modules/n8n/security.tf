# Security Group with improved rule definitions
resource "aws_security_group" "n8n_sg" {
  name        = "${var.name_prefix}-security-group"
  description = "Security group for n8n instance"
  vpc_id      = aws_vpc.n8n_vpc.id

  # Use dynamic blocks for security group rules
  dynamic "ingress" {
    for_each = {
      ssh = {
        port        = 22
        protocol    = "tcp"
        cidr_blocks = [var.ssh_cidr_blocks]
        description = "SSH access (restricted)"
      }
      http = {
        port        = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP access for Let's Encrypt validation and redirects"
      }
      https = {
        port        = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS secure access"
      }
      n8n = {
        port        = 5678
        protocol    = "tcp"
        cidr_blocks = var.n8n_direct_access ? ["0.0.0.0/0"] : ["127.0.0.1/32"]
        description = "n8n webhook access (conditional)"
      }
    }
    
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-sg"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}