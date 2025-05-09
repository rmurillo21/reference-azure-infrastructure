
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
    virtual_network_name = data.azurerm_virtual_network.existing.name
    resource_group_name  = data.azurerm_virtual_network.existing.resource_group_name
}
