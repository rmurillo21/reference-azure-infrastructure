output "graylog_admin_credentials" {
    value     = "Admin credentials stored in Key Vault: ${azurerm_key_vault.graylog_secrets.name}"
    sensitive = true
}
