variable "resource_group_name"    { type = string }
variable "location"               { type = string }
variable "env"                    { type = string }
variable "vnet_address_space"     { type = list(string) }
variable "subnet_web_prefix"      { type = string }
variable "subnet_bastion_prefix"  { type = string }
variable "subnet_firewall_prefix" { type = string }
variable "subnet_appgw_prefix" { type = string }
variable "log_analytics_workspace_id" {
    type = string 
    default = "" 
}
variable "tags" { 
    type = map(string) 
    default = {} 
}

