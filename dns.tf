locals {
  dns_zones = {
    "privatelink.azurecr.io"          = "acr"
    "privatelink.blob.core.windows.net" = "blob"
    "privatelink.postgres.database.azure.com" = "postgres"
    "privatelink.azurewebsites.net"  = "containerapps" # Internal Environment FQDNs
  }
}

resource "azurerm_private_dns_zone" "zones" {
  for_each = local.dns_zones

  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each = local.dns_zones

  name                  = "link-${each.value}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.key].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Weitere VNets (Hub, On-Prem via VPN) analog verlinken!