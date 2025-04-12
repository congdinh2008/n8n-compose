output "instance_id" {
  description = "The ID of the n8n instance"
  value       = google_compute_instance.n8n.id
}

output "instance_name" {
  description = "The name of the n8n instance"
  value       = google_compute_instance.n8n.name
}

output "instance_self_link" {
  description = "The self-link of the n8n instance"
  value       = google_compute_instance.n8n.self_link
}

output "ip_address" {
  description = "The external IP address of the n8n instance"
  value       = var.enable_static_ip ? google_compute_address.n8n[0].address : google_compute_instance.n8n.network_interface[0].access_config[0].nat_ip
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.n8n.id
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = google_compute_subnetwork.n8n.id
}

output "service_account" {
  description = "The service account email"
  value       = var.create_service_account ? google_service_account.n8n[0].email : var.service_account_email
}

output "n8n_url" {
  description = "The URL to access n8n"
  value       = "${var.n8n_protocol}://${var.subdomain != "" ? "${var.subdomain}." : ""}${var.domain_name}"
}
