output "frontdoor_endpoint_hostname" {
  value = azurerm_cdn_frontdoor_endpoint.fd.host_name
}

output "frontdoor_profile_id" {
  value = azurerm_cdn_frontdoor_profile.fd.id
}

output "waf_policy_id" {
  value = azurerm_cdn_frontdoor_firewall_policy.waf.id
}
