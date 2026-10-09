// Application Gateway mit WAF -> APIM

resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-${var.prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ipconfig"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Backend: APIM internal ILB
  # Für internes APIM verwenden wir die Gateway-URL (FQDN)
  backend_address_pool {
    name         = "apim"
    fqdns        = [azurerm_api_management.apim.gateway_url]
  }

  backend_http_settings {
    name                  = "apim-http"
    port                  = 80
    protocol              = "Http"
    pick_host_name_from_backend_address = true
    request_timeout       = 60
    cookie_based_affinity = "Disabled"
  }

  http_listener {
    name                           = "https"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "https"
    protocol                       = "Https"
    ssl_certificate_name           = "apim-cert" # Zertifikat separat hochladen (Key Vault empfohlen)
  }

  request_routing_rule {
    name               = "default"
    rule_type          = "Basic"
    http_listener_name = "https"
    backend_address_pool_name  = "apim"
    backend_http_settings_name = "apim-http"
    priority           = 100
  }

  # WAF im Prevention-Mode
  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}