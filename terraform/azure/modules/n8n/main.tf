terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0.0"
}

# Resource Group
resource "azurerm_resource_group" "n8n" {
  name     = "${var.name_prefix}-rg"
  location = var.location
  tags     = var.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "n8n" {
  name                = "${var.name_prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.n8n.location
  resource_group_name = azurerm_resource_group.n8n.name
  tags                = var.common_tags
}

# Subnet
resource "azurerm_subnet" "n8n" {
  name                 = "${var.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.n8n.name
  virtual_network_name = azurerm_virtual_network.n8n.name
  address_prefixes     = [var.subnet_cidr]
}

# Public IP (Optional)
resource "azurerm_public_ip" "n8n" {
  count               = var.enable_public_ip ? 1 : 0
  name                = "${var.name_prefix}-public-ip"
  location            = azurerm_resource_group.n8n.location
  resource_group_name = azurerm_resource_group.n8n.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

# Network Security Group
resource "azurerm_network_security_group" "n8n" {
  name                = "${var.name_prefix}-nsg"
  location            = azurerm_resource_group.n8n.location
  resource_group_name = azurerm_resource_group.n8n.name
  tags                = var.common_tags
}

# Network Security Rules
resource "azurerm_network_security_rule" "n8n" {
  for_each                    = { for i, rule in var.security_rules : i => rule }
  name                        = "rule-${each.key}"
  priority                    = 100 + each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = each.value.protocol
  source_port_range           = "*"
  destination_port_range      = each.value.port
  source_address_prefixes     = each.value.cidr_blocks
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.n8n.name
  network_security_group_name = azurerm_network_security_group.n8n.name
}

# Network Interface
resource "azurerm_network_interface" "n8n" {
  name                = "${var.name_prefix}-nic"
  location            = azurerm_resource_group.n8n.location
  resource_group_name = azurerm_resource_group.n8n.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.n8n.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.n8n[0].id : null
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "n8n" {
  network_interface_id      = azurerm_network_interface.n8n.id
  network_security_group_id = azurerm_network_security_group.n8n.id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "n8n" {
  name                = "${var.name_prefix}-vm"
  location            = azurerm_resource_group.n8n.location
  resource_group_name = azurerm_resource_group.n8n.name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.n8n.id,
  ]

  # Spot VM configuration
  priority        = var.use_spot_instance ? "Spot" : "Regular"
  eviction_policy = var.use_spot_instance ? var.spot_eviction_policy : null
  max_bid_price   = var.use_spot_instance && var.spot_max_price >= 0 ? var.spot_max_price : null

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  custom_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
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
  }))

  dynamic "identity" {
    for_each = var.create_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = var.common_tags

  lifecycle {
    ignore_changes = [
      tags["LastBackup"],
      tags["AutoUpdate"],
    ]
  }
}

# Note: The initialization script is provided via custom_data and doesn't need a separate VM extension
# Removed the redundant azurerm_virtual_machine_extension "n8n" resource

# Backup Configuration (Optional)
resource "azurerm_recovery_services_vault" "n8n" {
  count               = var.enable_backups ? 1 : 0
  name                = "${var.name_prefix}-recovery-vault"
  location            = azurerm_resource_group.n8n.location
  resource_group_name = azurerm_resource_group.n8n.name
  sku                 = "Standard"
  soft_delete_enabled = true
  tags                = var.common_tags
}

resource "azurerm_backup_policy_vm" "n8n" {
  count               = var.enable_backups ? 1 : 0
  name                = "${var.name_prefix}-backup-policy"
  resource_group_name = azurerm_resource_group.n8n.name
  recovery_vault_name = azurerm_recovery_services_vault.n8n[0].name

  timezone = var.timezone

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

resource "azurerm_backup_protected_vm" "n8n" {
  count               = var.enable_backups ? 1 : 0
  resource_group_name = azurerm_resource_group.n8n.name
  recovery_vault_name = azurerm_recovery_services_vault.n8n[0].name
  source_vm_id        = azurerm_linux_virtual_machine.n8n.id
  backup_policy_id    = azurerm_backup_policy_vm.n8n[0].id
}

# Azure Monitor Diagnostic Settings (Optional)
resource "azurerm_monitor_diagnostic_setting" "n8n" {
  count                      = var.create_monitoring ? 1 : 0
  name                       = "${var.name_prefix}-diagnostic-setting"
  target_resource_id         = azurerm_linux_virtual_machine.n8n.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true
    # Removed deprecated retention_policy block
  }
}
