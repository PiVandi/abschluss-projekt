terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
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
  subscription_id                 = "80ea84e8-afce-4851-928a-9e2219724c69"
  resource_provider_registrations = "none"
}