output "firewall_id"         { value = azurerm_firewall.fw.id }
output "firewall_private_ip" { value = azurerm_firewall.fw.ip_configuration[0].private_ip_address }
output "route_table_id"      { value = azurerm_route_table.web.id }
