resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"  # required for AAD/native SSH auth
  tags                = var.tags

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_monitor_diagnostic_setting" "bastion" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-bastion-${var.env}"
  target_resource_id        = azurerm_bastion_host.bastion.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "BastionAuditLogs"
  }
  metric {
    category = "AllMetrics"
  }
}
