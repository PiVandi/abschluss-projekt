output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "container_app_environment_fqdn_suffix" {
  value = azurerm_container_app_environment.env.default_domain
}

output "apim_gateway_url" {
  value = azurerm_api_management.apim.gateway_url
}

output "appgw_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}