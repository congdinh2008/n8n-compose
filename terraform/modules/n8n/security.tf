# Security Group
resource "aws_security_group" "n8n_sg" {
  name        = "${var.name_prefix}-security-group"
  description = "Security group for n8n instance"
  vpc_id      = aws_vpc.n8n_vpc.id

  dynamic "ingress" {
    for_each = var.security_group_rules
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
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-sg"
  })
}