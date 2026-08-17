variable "log_analytics_workspace_id" { type = string }
variable "tags" {
    type = map(string)
    default = {}
}