# Configure the Azure provider
provider "azurerm" {
    features {}
    subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}


locals {
    resource_name = "${var.prefix}-${var.env}-${var.location}-${var.project_name}"
    
    tags = {
        Owner       = var.owner
        Terraform   = "true"
        Project     = var.project_name
        Prefix      = var.prefix
        Environment = var.env
        Purpose     = "Loggin with Graylog"
    }
}

resource "azurerm_resource_group" "graylog" {
    name     = var.graylog_rg
    location = var.location
}

# Key Vault for secrets
resource "azurerm_key_vault" "graylog_secrets" {
    name                        = "${local.resource_name}-kv"
    location                    = azurerm_resource_group.graylog.location
    resource_group_name         = azurerm_resource_group.graylog.name
    enabled_for_disk_encryption = true
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    sku_name                    = "standard"
    soft_delete_retention_days  = 7
    purge_protection_enabled    = false

    access_policy {
        tenant_id = data.azurerm_client_config.current.tenant_id
        object_id = data.azurerm_client_config.current.object_id

        secret_permissions = [
            "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
        ]
    }
}

resource "random_string" "suffix" {
    length  = 8
    special = false
    upper   = false
}

# Generate secure passwords
resource "random_password" "graylog_admin" {
    length           = 24
    special          = true
    override_special = "!@#%^&*()-_=+[]{}<>:?"
}

resource "random_password" "graylog_secret" {
    length  = 64
    special = false
}

resource "random_password" "mongodb_password" {
    length  = 24
    special = false
}

# Store secrets in Key Vault
resource "azurerm_key_vault_secret" "graylog_admin_password" {
    name         = "${local.resource_name}-admin-passwd"
    value        = random_password.graylog_admin.result
    key_vault_id = azurerm_key_vault.graylog_secrets.id
}

resource "azurerm_key_vault_secret" "graylog_secret_key" {
    name         = "${local.resource_name}-secret-key"
    value        = random_password.graylog_secret.result
    key_vault_id = azurerm_key_vault.graylog_secrets.id
}

resource "azurerm_key_vault_secret" "mongodb_password" {
    name         = "${local.resource_name}-mongodb-passwd"
    value        = random_password.mongodb_password.result
    key_vault_id = azurerm_key_vault.graylog_secrets.id
}

# Network Security Group
resource "azurerm_network_security_group" "graylog" {
    name                = "${local.resource_name}-nsg"
    location            = azurerm_resource_group.graylog.location
    resource_group_name = azurerm_resource_group.graylog.name

    security_rule {
            name                       = "allow-graylog"
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "9000"
            source_address_prefix      = data.azurerm_subnet.frontend.address_prefix
            destination_address_prefix = "*"
        }

    security_rule {
        name                       = "allow-ssh"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "85.122.229.245/32" 
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "allow-internal"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["9200", "27017"] # Elasticsearch and MongoDB
        source_address_prefix      = data.azurerm_subnet.frontend.address_prefix
        destination_address_prefix = "*"
    }
}

# Associate NSG with subnets
resource "azurerm_subnet_network_security_group_association" "frontend" {
    subnet_id                 = data.azurerm_subnet.frontend.id
    network_security_group_id = azurerm_network_security_group.graylog.id
}

resource "azurerm_subnet_network_security_group_association" "backend" {
    subnet_id                 = data.azurerm_subnet.backend.id
    network_security_group_id = azurerm_network_security_group.graylog.id
}

# Managed Identity for VMs
resource "azurerm_user_assigned_identity" "graylog_vms" {
    resource_group_name = azurerm_resource_group.graylog.name
    location            = azurerm_resource_group.graylog.location
    name                = "${local.resource_name}-vms-identity"
}

resource "azurerm_key_vault_access_policy" "graylog_vms" {
    key_vault_id = azurerm_key_vault.graylog_secrets.id
    tenant_id    = data.azurerm_client_config.current.tenant_id
    object_id    = azurerm_user_assigned_identity.graylog_vms.principal_id

    secret_permissions = [
    "Get"
    ]
}

# NIC
resource "azurerm_network_interface" "frontend" {
    name                = "${local.resource_name}-frontend-nic"
    location            = azurerm_resource_group.graylog.location
    resource_group_name = azurerm_resource_group.graylog.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = data.azurerm_subnet.frontend.id  
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_linux_virtual_machine" "graylog_frontend" {
    name                = "${local.resource_name}-frontend-vm"
    resource_group_name = azurerm_resource_group.graylog.name
    location            = azurerm_resource_group.graylog.location
    size                = var.frontend_instance_size
    admin_username      = "graylogadmin"
    priority            = "Spot"
    eviction_policy     = "Deallocate"
    zone                = "1"

    custom_data = base64encode(templatefile("${path.module}/cloud-init/graylog.yaml"))

    network_interface_ids = [azurerm_network_interface.frontend.id]

    admin_ssh_key {
        username   = "graylogadmin"
        public_key = data.azurerm_ssh_public_key.main.public_key
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "20_04-lts" 
        version   = "latest"
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 128
    }

    lifecycle {
        ignore_changes = [
            priority,
            tags
        ]
        create_before_destroy = true
    }

    tags = local.tags
}

# Backend VM (Graylog Server + MongoDB + Elasticsearch)
resource "azurerm_network_interface" "backend" {
    name                = "${local.resource_name}-backend-nic"
    location            = azurerm_resource_group.graylog.location
    resource_group_name = azurerm_resource_group.graylog.name

    ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
    }
}


resource "azurerm_linux_virtual_machine" "graylog_backend" {
    name                = "graylog-backend-vm"
    resource_group_name = azurerm_resource_group.graylog.name
    location            = azurerm_resource_group.graylog.location
    size                = var.backend_instance_size
    admin_username      = "graylogadmin"
    priority            = "Spot"
    eviction_policy     = "Deallocate"
    zone                = "1"

    network_interface_ids = [azurerm_network_interface.backend.id]

    admin_ssh_key {
        username   = "graylogadmin"
        public_key = data.azurerm_ssh_public_key.main.public_key
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "20_04-lts"
        version   = "latest"
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 128 
    }

    identity {
        type         = "UserAssigned"
        identity_ids = [azurerm_user_assigned_identity.graylog_vms.id]
    }

    custom_data = base64encode(templatefile("${path.module}/cloud-init/backend.yaml", {
        key_vault_name = azurerm_key_vault.graylog_secrets.name
    }))


    tags = local.tags

    lifecycle {
        ignore_changes = [
            priority,
            tags
        ]
    }
}

resource "azurerm_network_security_group" "graylog" {
    name                = "graylog-nsg"
    location            = azurerm_resource_group.graylog.location
    resource_group_name = azurerm_resource_group.graylog.name

    security_rule {
        name                       = "allow-graylog-web"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "9000"
        source_address_prefix      = "10.0.1.0/24"  
        destination_address_prefix = "*"
    }
}
