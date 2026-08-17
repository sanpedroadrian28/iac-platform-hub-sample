variable "resource_group_name"        { type = string }
variable "env"                        { type = string }
variable "appgw_public_ip"            { type = string }  # origin = App Gateway public IP/FQDN
variable "custom_domain_host_name"    {
    type = string
    default = ""
}
variable "log_analytics_workspace_id" { 
    type = string
    default = ""
}
variable "waf_mode" {
    type = string
    default = "Prevention"
}
variable "tags" { 
    type = map(string)
    default = {}
}
