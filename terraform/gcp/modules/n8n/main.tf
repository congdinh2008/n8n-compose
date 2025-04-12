terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

# GCP Compute Instance
resource "google_compute_instance" "n8n" {
  name         = "${var.name_prefix}-instance"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["n8n", "http-server", "https-server", "ssh"]

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.ssh_pub_key_path)}"
  }

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  network_interface {
    network    = google_compute_network.n8n.self_link
    subnetwork = google_compute_subnetwork.n8n.self_link

    access_config {
      // Ephemeral public IP
      nat_ip = var.enable_static_ip ? google_compute_address.n8n[0].address : null
    }
  }

  # Enable deletion protection for production instances
  deletion_protection = var.enable_deletion_protection
  
  # Enable OS login for better security (optional)
  metadata_startup_script = templatefile("${path.module}/templates/user_data.sh.tpl", {
    domain_name         = var.domain_name
    subdomain           = var.subdomain
    timezone            = var.timezone
    ssl_email           = var.ssl_email
    n8n_protocol        = var.n8n_protocol
    db_user             = var.db_user
    db_password         = var.db_password
    db_name             = var.db_name
    enable_basic_auth   = var.enable_basic_auth
    basic_auth_user     = var.basic_auth_user
    basic_auth_password = var.basic_auth_password
    enable_auto_backup  = var.enable_auto_backup
  })

  service_account {
    email  = var.create_service_account ? google_service_account.n8n[0].email : var.service_account_email
    scopes = ["cloud-platform"]
  }

  scheduling {
    preemptible         = var.use_preemptible
    automatic_restart   = var.use_preemptible ? false : true
    on_host_maintenance = var.use_preemptible ? "TERMINATE" : "MIGRATE"
  }

  shielded_instance_config {
    enable_secure_boot          = var.enable_secure_boot
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # Store the instance id for later use
  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],
      labels["last_backup"],
    ]
  }
}

# Static IP (Optional)
resource "google_compute_address" "n8n" {
  count        = var.enable_static_ip ? 1 : 0
  name         = "${var.name_prefix}-ip"
  region       = var.region
  address_type = "EXTERNAL"
}

# Service Account (Optional)
resource "google_service_account" "n8n" {
  count        = var.create_service_account ? 1 : 0
  account_id   = "${var.name_prefix}-sa"
  display_name = "N8N Service Account"
}

# IAM role binding (Optional)
resource "google_project_iam_member" "n8n" {
  count   = var.create_service_account && length(var.service_account_roles) > 0 ? length(var.service_account_roles) : 0
  project = var.project_id
  role    = var.service_account_roles[count.index]
  member  = "serviceAccount:${google_service_account.n8n[0].email}"
}

# Cloud Scheduler for backup (Optional)
resource "google_cloud_scheduler_job" "backup" {
  count       = var.enable_scheduled_backups ? 1 : 0
  name        = "${var.name_prefix}-backup"
  region      = var.region
  description = "Regularly scheduled backup for n8n instance"
  schedule    = var.backup_schedule

  http_target {
    http_method = "POST"
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instances/${google_compute_instance.n8n.name}/createSnapshot"
    
    oauth_token {
      service_account_email = var.create_service_account ? google_service_account.n8n[0].email : var.service_account_email
    }
  }
}
