variable "resource_group_name"        { type = string }
variable "location"                   { type = string }
variable "env"                        { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "vmss_id"                    { type = string }
variable "tags" { 
    type = map(string)
    default = {}
}
