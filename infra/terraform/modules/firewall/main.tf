resource "azurerm_public_ip" "fw" {
  name                = "pip-fw-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_firewall_policy" "fw" {
  name                = "fw-policy-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "egress" {
  name               = "NodeAppEgressRules"
  firewall_policy_id = azurerm_firewall_policy.fw.id
  priority           = 200

  application_rule_collection {
    name     = "AllowNodeAppEgress"
    priority = 200
    action   = "Allow"

    rule {
      name = "AllowNpmRegistry"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = ["10.0.1.0/24"]
      destination_fqdns = ["registry.npmjs.org", "*.npmjs.org"]
    }

    rule {
      name = "AllowUbuntuRepos"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = ["10.0.1.0/24"]
      destination_fqdns = ["*.ubuntu.com", "security.ubuntu.com"]
    }
  }
}

resource "azurerm_firewall" "fw" {
  name                = "fw-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones               = ["1", "2", "3"]
  firewall_policy_id  = azurerm_firewall_policy.fw.id
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.fw.id
  }
}

resource "azurerm_route_table" "web" {
  name                = "rt-web-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "web" {
  count          = length(var.route_table_subnet_ids)
  subnet_id      = var.route_table_subnet_ids[count.index]
  route_table_id = azurerm_route_table.web.id
}

resource "azurerm_monitor_diagnostic_setting" "fw" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-fw-${var.env}"
  target_resource_id        = azurerm_firewall.fw.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }
  enabled_log {
    category = "AzureFirewallNetworkRule"
  }
  metric {
    category = "AllMetrics"
  }
}
