# Configure the Azure provider
provider "azurerm" {
    features {}
    subscription_id = var.subscription_id
}

locals {
    resource_name = "${var.prefix}-${var.env}-${var.location}-${var.project_name}"
}

resource "azurerm_resource_group" "graylog" {
    name     = var.graylog_rg
    location = var.location
}

# NIC
resource "azurerm_network_interface" "frontend" {
    name                = "${local.resource_name}-nic"
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

    custom_data = filebase64("${path.module}/install_frontend.sh")
    network_interface_ids = [azurerm_network_interface.frontend.id]

    admin_ssh_key {
        username   = "graylogadmin"
        public_key = file("~/.ssh/id_rsa.pub")
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
        disk_size_gb         = 64
    }

    lifecycle {
        ignore_changes = [
            priority,
            tags
        ]
        create_before_destroy = true
    }

    tags = {
        Environment = var.env
        Application = "Graylog"
        Component   = "Frontend"
        SpotVM      = "true"
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

    network_interface_ids = [azurerm_network_interface.backend.id]

    admin_ssh_key {
        username   = "graylogadmin"
        public_key = file("~/.ssh/id_rsa.pub")
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

    custom_data = filebase64("${path.module}/install_backend.sh")

    tags = {
        Environment = "Production"
        Application = "Graylog"
        Component   = "Backend"
        SpotVM      = "true"
    }

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
