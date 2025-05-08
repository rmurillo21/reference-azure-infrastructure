resource "azurerm_storage_management_policy" "graylog_retention" {
  storage_account_id = data.azurerm_storage_account.graylog.id

  rule {
    name    = "delete-old-backups"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["graylog-backups/"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 7
      }
    }
  }
}

