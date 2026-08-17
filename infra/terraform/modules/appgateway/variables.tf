variable "resource_group_name"        { type = string }
variable "location"                   { type = string }
variable "env"                        { type = string }
variable "appgw_subnet_id"            { type = string }
variable "backend_fqdns"              { 
    type = list(string)
    default = []
}
variable "backend_ip_addresses" { 
    type = list(string)
    default = []
}
variable "log_analytics_workspace_id" {
    type = string
    default = ""
}
variable "waf_mode" { 
    type = string
    default = "Prevention"
} # or "Detection"
variable "tags" { 
    type = map(string)
    default = {}
}

variable "ssl_cert_password" {
    type      = string
    default   = ""
    sensitive = true
}
