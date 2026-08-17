env                    = "dev"
location               = "australiaeast"
resource_group_name    = "rg-nodeapp-dev"

vnet_address_space     = ["10.0.0.0/16"]
subnet_web_prefix      = "10.0.1.0/24"
subnet_bastion_prefix  = "10.0.4.0/27"
subnet_firewall_prefix = "10.0.5.0/26"

vmss_instance_count    = 6
vmss_vm_size           = "Standard_D2s_v5"
vmss_admin_username    = "azureuser"
ssh_public_key         = "ssh-rsa AAAAB3NzaC1yc2EA... replace-with-real-key"
golden_image_id        = ""

log_analytics_sku      = "PerGB2018"
log_retention_days     = 30

tags = {
  project     = "nodeapp"
  environment = "dev"
  managed_by  = "terraform"
}
