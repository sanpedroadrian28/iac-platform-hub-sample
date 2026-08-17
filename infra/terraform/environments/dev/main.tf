resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "log_analytics" {
  source              = "../../modules/log-analytics"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  env                 = var.env
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

module "network" {
  source                     = "../../modules/network"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  env                        = var.env
  vnet_address_space         = var.vnet_address_space
  subnet_web_prefix          = var.subnet_web_prefix
  subnet_bastion_prefix      = var.subnet_bastion_prefix
  subnet_firewall_prefix     = var.subnet_firewall_prefix
  subnet_appgw_prefix        = var.subnet_appgw_prefix
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = var.tags
}

module "firewall" {
  source                     = "../../modules/firewall"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  env                        = var.env
  firewall_subnet_id         = module.network.firewall_subnet_id
  route_table_subnet_ids     = [module.network.web_subnet_id]
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = var.tags
}

module "bastion" {
  source                     = "../../modules/bastion"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  env                        = var.env
  bastion_subnet_id          = module.network.bastion_subnet_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = var.tags
}

module "vmss" {
  source              = "../../modules/vmss"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  env                 = var.env
  instance_count      = var.vmss_instance_count
  vm_size             = var.vmss_vm_size
  admin_username      = var.vmss_admin_username
  ssh_public_key      = var.ssh_public_key
  golden_image_id     = var.golden_image_id
  web_subnet_id       = module.network.web_subnet_id
  nsg_web_id          = module.network.nsg_web_id
  lb_pool_id          = module.appgateway.appgw_backend_pool_id
  tags                = var.tags

  depends_on = [module.firewall, module.bastion]
}

module "appgateway" {
  source                     = "../../modules/appgateway"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  env                        = var.env
  appgw_subnet_id            = module.network.appgw_subnet_id
  backend_ip_addresses       = []  # populate via VMSS backend pool association, or use FQDNs below
  backend_fqdns              = []
  waf_mode                   = var.waf_mode
  ssl_cert_password          = var.ssl_cert_password
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = var.tags

  depends_on = [module.vmss]
}

module "frontdoor" {
  source                     = "../../modules/frontdoor"
  resource_group_name        = azurerm_resource_group.rg.name
  env                        = var.env
  appgw_public_ip            = module.appgateway.appgw_public_ip
  custom_domain_host_name    = var.custom_domain_host_name
  waf_mode                   = var.waf_mode
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = var.tags

  depends_on = [module.appgateway]
}

module "azure_monitor" {
  source                     = "../../modules/azure-monitor"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  env                        = var.env
  log_analytics_workspace_id = module.log_analytics.workspace_id
  vmss_id                    = module.vmss.vmss_id
  tags                       = var.tags
}

module "defender" {
  source                     = "../../modules/defender"
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = var.tags
}
