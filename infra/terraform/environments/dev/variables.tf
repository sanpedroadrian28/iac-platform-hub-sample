variable "env" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "australiaeast"
}

variable "resource_group_name" {
  description = "Resource group name for this environment"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_web_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_bastion_prefix" {
  type    = string
  default = "10.0.4.0/27"
}

variable "subnet_firewall_prefix" {
  type    = string
  default = "10.0.5.0/26"
}

variable "vmss_instance_count" {
  type    = number
  default = 6
}

variable "vmss_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "vmss_admin_username" {
  type      = string
  default   = "azureuser"
  sensitive = true
}

variable "ssh_public_key" {
  description = "SSH public key for VMSS admin login"
  type        = string
  sensitive   = true
}

variable "golden_image_id" {
  description = "Resource ID of the golden image (Packer/Azure Image Builder output)"
  type        = string
  default     = ""
}

variable "log_analytics_sku" {
  type    = string
  default = "PerGB2018"
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "subnet_appgw_prefix" {
  description = "Subnet for Application Gateway"
  type        = string
  default     = "10.0.6.0/24"
}

variable "waf_mode" {
  description = "WAF mode for App Gateway and Front Door (Detection or Prevention)"
  type        = string
  default     = "Prevention"
}

variable "ssl_cert_password" {
  description = "Password for the App Gateway SSL certificate (source from Key Vault/CI secret in real use)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "custom_domain_host_name" {
  description = "Optional custom domain for Front Door endpoint"
  type        = string
  default     = ""
}

variable "tags" {
  type = map(string)
  default = {
    project     = "nodeapp"
    environment = "dev"
    managed_by  = "terraform"
  }
}
