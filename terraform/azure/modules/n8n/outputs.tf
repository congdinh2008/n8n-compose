output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.n8n.name
}

output "vm_id" {
  description = "The ID of the VM"
  value       = azurerm_linux_virtual_machine.n8n.id
}

output "vm_name" {
  description = "The name of the VM"
  value       = azurerm_linux_virtual_machine.n8n.name
}

output "private_ip_address" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.n8n.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = var.enable_public_ip ? azurerm_public_ip.n8n[0].ip_address : "No public IP assigned"
}

output "fqdn" {
  description = "The fully qualified domain name for n8n"
  value       = "${var.subdomain}.${var.domain_name}"
}

output "n8n_url" {
  description = "The URL to access n8n"
  value       = "${var.n8n_protocol}://${var.subdomain}.${var.domain_name}"
}
