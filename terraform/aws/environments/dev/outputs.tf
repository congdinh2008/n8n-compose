output "n8n_public_ip" {
  description = "Public IP address of the n8n instance"
  value       = module.n8n.public_ip
}

output "n8n_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.n8n.instance_id
}

output "n8n_url" {
  description = "URL to access n8n"
  value       = module.n8n.n8n_url
}

output "n8n_public_dns" {
  description = "Public DNS of the n8n instance"
  value       = module.n8n.public_dns
}