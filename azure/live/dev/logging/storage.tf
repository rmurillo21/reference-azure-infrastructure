#resource "azurerm_storage_share" "graylog_logs" {
#  name                 = "graylog-logs"
#  storage_account_name = var.storage_account_name
#  quota                = 512
#  resource_group_name  = var.storage_rg
#}

#resource "azurerm_storage_container" "graylog_backups" {
#  name                  = "graylog-backups"
#  storage_account_name  = var.storage_account_name
#  container_access_type = "private"
#}
