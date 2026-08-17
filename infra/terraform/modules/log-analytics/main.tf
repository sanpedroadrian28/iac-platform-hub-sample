resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

resource "azurerm_log_analytics_solution" "vm_insights" {
  solution_name         = "VMInsights"
  resource_group_name   = var.resource_group_name
  location              = var.location
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  workspace_name        = azurerm_log_analytics_workspace.law.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "dcr-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
      name                  = "law-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog", "Microsoft-InsightsMetrics"]
    destinations = ["law-destination"]
  }

  data_sources {
    syslog {
      facility_names = ["auth", "authpriv", "daemon", "syslog"]
      log_levels     = ["Warning", "Error", "Critical"]
      name           = "syslog-datasource"
      streams        = ["Microsoft-Syslog"]
    }

    performance_counter {
      streams                      = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["Processor(*)\\% Processor Time", "Memory(*)\\% Used Memory"]
      name                          = "perfcounter-datasource"
    }
  }
}
