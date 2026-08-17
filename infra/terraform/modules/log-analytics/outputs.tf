output "workspace_id"   { value = azurerm_log_analytics_workspace.law.id }
output "workspace_name" { value = azurerm_log_analytics_workspace.law.name }
output "dcr_id"         { value = azurerm_monitor_data_collection_rule.dcr.id }
