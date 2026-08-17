resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "waf" {
  name                = "waf-policy-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  zones               = ["1", "2", "3"]
  firewall_policy_id  = azurerm_web_application_firewall_policy.waf.id
  tags                = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }

  gateway_ip_configuration {
    name      = "appgw-ipconfig"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = "frontend-port-443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ipconfig"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name         = "nodeapp-backend-pool"
    fqdns        = var.backend_fqdns
    ip_addresses = var.backend_ip_addresses
  }

  backend_http_settings {
    name                  = "nodeapp-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 30
    probe_name            = "nodeapp-health-probe"
  }

  probe {
    name                = "nodeapp-health-probe"
    protocol            = "Https"
    path                = "/healthz"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    host                = "127.0.0.1"
  }

  http_listener {
    name                           = "nodeapp-https-listener"
    frontend_ip_configuration_name = "frontend-ipconfig"
    frontend_port_name             = "frontend-port-443"
    protocol                       = "Https"
    ssl_certificate_name           = "nodeapp-ssl-cert"
  }

  ssl_certificate {
    name     = "nodeapp-ssl-cert"
    data     = filebase64("${path.module}/certs/nodeapp.pfx") # replace with Key Vault-sourced cert in prod
    password = var.ssl_cert_password
  }

  request_routing_rule {
    name                       = "nodeapp-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "nodeapp-https-listener"
    backend_address_pool_name  = "nodeapp-backend-pool"
    backend_http_settings_name = "nodeapp-http-settings"
    priority                   = 100
  }
}

resource "azurerm_monitor_diagnostic_setting" "appgw" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-appgw-${var.env}"
  target_resource_id        = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }
  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }
  metric {
    category = "AllMetrics"
  }
}
