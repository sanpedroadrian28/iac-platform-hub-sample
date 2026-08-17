resource "azurerm_monitor_action_group" "ops_team" {
  name                = "ag-nodeapp-ops-${var.env}"
  resource_group_name = var.resource_group_name
  short_name          = "nodeapp-ops"
  tags                = var.tags

  email_receiver {
    name          = "ops-email"
    email_address = "devops-team@company.com"
  }
}

resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "alert-high-cpu-${var.env}"
  resource_group_name = var.resource_group_name
  scopes              = [var.vmss_id]
  description         = "Alert when average CPU exceeds 80% for 15 minutes"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops_team.id
  }
}

resource "azurerm_monitor_diagnostic_setting" "vmss" {
  name                       = "diag-vmss-${var.env}"
  target_resource_id        = var.vmss_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Administrative"
  }
  metric {
    category = "AllMetrics"
  }
}
