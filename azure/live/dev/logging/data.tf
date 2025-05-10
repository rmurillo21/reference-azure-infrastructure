
# Vnet
data "azurerm_virtual_network" "main" {
    name                = var.vnet_name
    resource_group_name = var.vnet_rg
}

# Subnets
data "azurerm_subnet" "frontend" {
    name                 = var.subnet_frontend # # Tu subnet existente para frontend
    virtual_network_name = data.azurerm_virtual_network.main.name
    resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
}

data "azurerm_subnet" "backend" {
    name                 = var.subnet_backend # Tu subnet existente para backend
    virtual_network_name = data.azurerm_virtual_network.main.name
    resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
}


data "azurerm_application_gateway" "main" {
    name                = var.app_gateway_name
    resource_group_name = var.app_gateway_rg
}

# ssh key
data "azurerm_ssh_public_key" "main" {
    name                = "${var.prefix}-${var.env}-ssh-key"
    resource_group_name = var.vnet_rg
}