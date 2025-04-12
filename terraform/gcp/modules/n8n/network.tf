# VPC Network
resource "google_compute_network" "n8n" {
  name                    = "${var.name_prefix}-network"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "n8n" {
  name          = "${var.name_prefix}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.n8n.id
}

# Firewall rules
resource "google_compute_firewall" "ssh" {
  name    = "${var.name_prefix}-allow-ssh"
  network = google_compute_network.n8n.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_ranges]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "http" {
  name    = "${var.name_prefix}-allow-http"
  network = google_compute_network.n8n.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "https" {
  name    = "${var.name_prefix}-allow-https"
  network = google_compute_network.n8n.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

resource "google_compute_firewall" "n8n_webhook" {
  count   = var.n8n_direct_access ? 1 : 0
  name    = "${var.name_prefix}-allow-n8n-webhook"
  network = google_compute_network.n8n.name

  allow {
    protocol = "tcp"
    ports    = ["5678"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["n8n"]
}

# Cloud NAT (optional - for instances without public IPs)
resource "google_compute_router" "n8n" {
  count   = var.enable_nat ? 1 : 0
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.n8n.id
}

resource "google_compute_router_nat" "n8n" {
  count                              = var.enable_nat ? 1 : 0
  name                               = "${var.name_prefix}-nat"
  router                             = google_compute_router.n8n[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
