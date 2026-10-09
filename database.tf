# --- PostgreSQL Flexible Server --------------------------------------
resource "azurerm_postgresql_flexible_server" "pg" {
  name                   = "pg-${var.prefix}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "16"
  administrator_login    = "pgadmin"
  administrator_password = "ChangeMe-Secret-From-KeyVault!" # Besser: aus Key Vault
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  backup_retention_days  = 7

  delegated_subnet_id    = azurerm_subnet.databases.id # Subnet mit Microsoft.DBforPostgreSQL/flexibleServers Delegation
  private_dns_zone_id    = azurerm_private_dns_zone.zones["privatelink.postgres.database.azure.com"].id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.links]
}

# --- Blob Storage ------------------------------------------------------
resource "azurerm_storage_account" "blob" {
  name                     = "st${replace(var.prefix, "-", "")}blob" # global eindeutig, nur Kleinbuchstaben und Zahlen
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false # Nur via Private Endpoint

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "blob-pec"
    private_connection_resource_id = azurerm_storage_account.blob.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.zones["privatelink.blob.core.windows.net"].id]
  }
}