resource "azurerm_security_center_subscription_pricing" "vms" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "arm" {
  tier          = "Standard"
  resource_type = "Arm"
}

resource "azurerm_security_center_workspace" "defender_workspace" {
  scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  workspace_id = var.log_analytics_workspace_id
}

resource "azurerm_security_center_contact" "security_contact" {
  name                = "default1"
  email               = "security-team@company.com"
  phone               = "+61-000-000-000"
  alert_notifications = true
  alerts_to_admins    = true
}

data "azurerm_client_config" "current" {}
