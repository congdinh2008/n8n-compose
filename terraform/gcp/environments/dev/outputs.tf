output "instance_id" {
  description = "The ID of the n8n instance"
  value       = module.n8n.instance_id
}

output "instance_name" {
  description = "The name of the n8n instance"
  value       = module.n8n.instance_name
}

output "ip_address" {
  description = "The external IP address of the n8n instance"
  value       = module.n8n.ip_address
}

output "n8n_url" {
  description = "The URL to access n8n"
  value       = module.n8n.n8n_url
}

output "service_account" {
  description = "The service account email used by the n8n instance"
  value       = module.n8n.service_account
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = module.n8n.network_id
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = module.n8n.subnet_id
}
