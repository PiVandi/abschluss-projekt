terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
  # Vorher in Azure Blob anlegen
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstateappv"
    key                  = "landingzone.tfstate" # was macht das?
    use_azuread_auth     = true                  # Was macht das?
  }

}

provider "azurerm" {
  features {}
  subscription_id                 = "2213e8b1-dbc7-4d54-8aff-b5e315df5e5b"
  resource_provider_registrations = "none"
}