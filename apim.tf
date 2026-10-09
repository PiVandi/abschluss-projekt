resource "azurerm_api_management" "apim" {
  name                 = "apim-${var.prefix}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  publisher_name       = var.apim_publisher_name
  publisher_email      = var.apim_publisher_email
  sku_name             = "Premium_1" # VNet-Integration ab Developer/Premium; für Prod: Premium
  virtual_network_type = "Internal" # Nur erreichbar aus dem VNet (via App Gateway)

  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim.id
  }

  # Optional: Private Endpoint zusätzlich (Premium) – hier über VNet-Integration abgedeckt
}