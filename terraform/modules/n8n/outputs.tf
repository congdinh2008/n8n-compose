output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.n8n.id
}

output "public_ip" {
  description = "Public IP of the n8n instance"
  value       = aws_instance.n8n.public_ip
}

output "public_dns" {
  description = "Public DNS of the n8n instance"
  value       = aws_instance.n8n.public_dns
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.n8n_vpc.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.n8n_subnet.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.n8n_sg.id
}

output "n8n_url" {
  description = "URL to access n8n"
  value       = "https://${var.subdomain}.${var.domain_name}"
}