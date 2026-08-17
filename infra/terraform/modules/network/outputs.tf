output "vnet_id"            { value = azurerm_virtual_network.vnet.id }
output "web_subnet_id"       { value = azurerm_subnet.web.id }
output "bastion_subnet_id"   { value = azurerm_subnet.bastion.id }
output "firewall_subnet_id"  { value = azurerm_subnet.firewall.id }
output "nsg_web_id"          { value = azurerm_network_security_group.web.id }
output "nsg_data_id"         { value = azurerm_network_security_group.data.id }
output "appgw_subnet_id" { value = azurerm_subnet.appgw.id }
