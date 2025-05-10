#resource "azurerm_application_gateway_backend_address_pool_address" "graylog_pool" {
#  count = var.graylog_count
#
#  application_gateway_name  = data.azurerm_application_gateway.main.name
#  resource_group_name       = data.azurerm_application_gateway.main.resource_group_name
#  backend_address_pool_name = "${local.resource_name}-backend-pool"  # Must exist already or be created manually
#  ip_address                = azurerm_network_interface.frontend.private_ip_address
#}
