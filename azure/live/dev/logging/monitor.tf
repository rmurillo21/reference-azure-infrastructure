resource "azurerm_monitor_metric_alert" "fileshare_usage_alert" {
  name                = "graylog-fileshare-usage-alert"
  resource_group_name = var.storage_rg
  scopes              = [azurerm_storage_share.graylog_logs.id]
  description         = "Alert if file share usage exceeds 80%"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts/fileServices"
    metric_name      = "FileShareUsedPercent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  severity     = 2
  frequency    = "PT5M"
  window_size  = "PT15M"

  action {
    action_group_id = "<your_action_group_id_here>" # replace with actual group
  }
}


