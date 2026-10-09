resource "azurerm_user_assigned_identity" "apps_pull" {
  name                = "id-containerapps-pull"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Container Apps dürfen Images aus der ACR ziehen (über den Private Endpoint)
resource "azurerm_role_assignment" "apps_acrpull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.apps_pull.principal_id
}

resource "azurerm_log_analytics_workspace" "env" {
  name                = "log-${var.prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                           = "cae-${var.prefix}"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  log_analytics_workspace_id    = azurerm_log_analytics_workspace.env.id
  infrastructure_subnet_id      = azurerm_subnet.container_apps.id
  internal_load_balancer_enabled = true # Environment nur intern erreichbar (kein Public Ingress)

  depends_on = [azurerm_private_endpoint.acr] # Erst wenn ACR erreichbar ist
}

# Placeholder-Container-App – wird von der Pipeline per
# `az containerapp update --image ...` mit dem echten Image ersetzt.
# IMPORTANT: ignore_changes verhindert, dass terraform apply die
# Pipeline-Deploys überschreibt.
resource "azurerm_container_app" "placeholder" {
  name                         = "app-placeholder"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "placeholder"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  ingress {
    external_enabled = false # Nur über APIM/ILB erreichbar
    target_port      = 80
    transport        = "http"
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
    ]
  }
}