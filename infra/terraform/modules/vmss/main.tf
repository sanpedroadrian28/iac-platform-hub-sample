# VMSS + autoscaling
resource "azurerm_linux_virtual_machine_scale_set" "nodeapp" {
  name                = "vmss-nodeapp-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard_D2s_v5"
  instances           = var.instance_count       # 6 default
  zones               = ["1", "2", "3"]
  zone_balance        = true
  upgrade_mode        = "Rolling"

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  source_image_id = var.golden_image_id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  network_interface {
    name    = "nic-web"
    primary = true

    ip_configuration {
      name                                   = "ipconfig1"
      primary                                = true
      subnet_id                              = var.web_subnet_id
      load_balancer_backend_address_pool_ids = [var.lb_pool_id]
    }
    network_security_group_id = var.nsg_web_id
  }

  extension {
    name                 = "AzureMonitorLinuxAgent"
    publisher            = "Microsoft.Azure.Monitor"
    type                 = "AzureMonitorLinuxAgent"
    type_handler_version = "1.29"
    auto_upgrade_minor_version = true
  }
}

resource "azurerm_monitor_autoscale_setting" "nodeapp" {
  name                = "autoscale-nodeapp"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.nodeapp.id

  profile {
    name = "default"
    capacity {
      minimum = "6"
      maximum = "15"
      default = "6"
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.nodeapp.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "3"           # scale in multiples of 3 (zone-balanced)
        cooldown  = "PT5M"
      }
    }
  }
}
