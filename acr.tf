resource "azurerm_container_registry" "acr" {
  name                          = "acr${replace(var.prefix, "-", "")}" # global eindeutig, alphanumerisch (Bindestriche entfernen)
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = "Premium" # Public Network Access mit IP-Regeln nur ab Premium konfigurierbar per IP-Regeln? -> Standard unterstützt Allowlist; Premium für Geo-Replikation
  admin_enabled                 = false
  public_network_access_enabled = true # IP-Allowlist für GitHub-Push, interner Pull via Private Endpoint

  network_rule_bypass_option = "AzureServices"
}

# Ingress-Regeln: nur GitHub Actions Runner-Ranges
#resource "azurerm_container_registry" "acr" {
#  # ... siehe oben (hier nur zur Illustration der Netzwerkregeln)
#}

# ACR IP-Allowlist wird aktuell per azurerm nicht direkt unterstützt ->
# Rest-Ressource oder az cli (scheduled Sync mit GitHub Meta API):
resource "azapi_resource" "acr_ip_rules" {
  type      = "Microsoft.ContainerRegistry/registries@2023-07-01"
  name      = azurerm_container_registry.acr.name
  parent_id = azurerm_resource_group.rg.id

  body = {
    properties = {
      networkRuleSet = {
        defaultAction = "Deny"
        ipRules = [for cidr in var.acr_ip_allowlist : { action = "Allow", value = cidr }]
      }
    }
    sku = {
      name = azurerm_container_registry.acr.sku
    }
  }
}

# Private Endpoint für ACR (Registry-Endpoint)
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "acr-pec"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.zones["privatelink.azurecr.io"].id]
  }
}

# Blob-Subresource der ACR (für Import/Manifeste) – optional, aber empfohlen
# Hinweis: nutzt eine eigene DNS-Zone <acr-name>.blob.core.windows.net
resource "azurerm_private_dns_zone" "acr_blob" {
  name                = "${azurerm_container_registry.acr.name}.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_blob" {
  name                  = "link-acr-blob"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# GitHub-Pipeline: AcrPush (OIDC-App Registration)
#resource "azurerm_role_assignment" "github_acrpush" {
#  scope                = azurerm_container_registry.acr.id
#  role_definition_name = "AcrPush"
#  principal_id         = var.github_oidc_object_id
#}