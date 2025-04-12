output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.n8n.resource_group_name
}

output "vm_id" {
  description = "The ID of the VM"
  value       = module.n8n.vm_id
}

output "vm_name" {
  description = "The name of the VM"
  value       = module.n8n.vm_name
}

output "private_ip_address" {
  description = "The private IP address of the VM"
  value       = module.n8n.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = module.n8n.public_ip_address
}

output "fqdn" {
  description = "The fully qualified domain name for n8n"
  value       = module.n8n.fqdn
}

output "n8n_url" {
  description = "The URL to access n8n"
  value       = module.n8n.n8n_url
}
