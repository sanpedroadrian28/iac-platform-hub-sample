output "action_group_id" { value = azurerm_monitor_action_group.ops_team.id }
output "cpu_alert_id"     { value = azurerm_monitor_metric_alert.high_cpu.id }
