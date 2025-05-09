output "graylog_ui_url" {
    value = "http://${data.azurerm_application_gateway.existing.frontend_ip_configuration[0].public_ip_address}"
}

    output "graylog_admin_credentials" {
    value     = "Admin credentials stored in Key Vault: ${azurerm_key_vault.graylog_secrets.name}"
    sensitive = true
}
