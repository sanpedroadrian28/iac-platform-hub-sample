variable "resource_group_name"       { type = string }
variable "location"                  { type = string }
variable "env"                       { type = string }
variable "firewall_subnet_id"        { type = string }
variable "route_table_subnet_ids"    { type = list(string) }
variable "log_analytics_workspace_id" { 
    type = string 
    default = "" 
}
variable "tags" { 
    type = map(string) 
    default = {} 
}
