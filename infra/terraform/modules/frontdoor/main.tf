resource "azurerm_cdn_frontdoor_profile" "fd" {
  name                = "fd-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"  # Premium required for Private Link to origin, WAF managed rules
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "fd" {
  name                     = "fde-nodeapp-${var.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "appgw" {
  name                     = "og-appgw-${var.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/healthz"
    request_type        = "GET"
    protocol            = "Https"
    interval_in_seconds = 30
  }
}

resource "azurerm_cdn_frontdoor_origin" "appgw" {
  name                          = "origin-appgw-${var.env}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.appgw.id

  enabled                        = true
  host_name                      = var.appgw_public_ip
  origin_host_header              = var.appgw_public_ip
  http_port                       = 80
  https_port                      = 443
  priority                        = 1
  weight                          = 1000
  certificate_name_check_enabled  = true
}

resource "azurerm_cdn_frontdoor_route" "appgw" {
  name                          = "route-nodeapp-${var.env}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.appgw.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.appgw.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true
}

resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name                = "fdwaf${var.env}"
  resource_group_name = var.resource_group_name
  sku_name            = azurerm_cdn_frontdoor_profile.fd.sku_name
  enabled             = true
  mode                = var.waf_mode
  tags                = var.tags

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "waf" {
  name                     = "fd-security-policy-${var.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.fd.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "fd" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-frontdoor-${var.env}"
  target_resource_id        = azurerm_cdn_frontdoor_profile.fd.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FrontDoorAccessLog"
  }
  enabled_log {
    category = "FrontDoorWebApplicationFirewallLog"
  }
}
