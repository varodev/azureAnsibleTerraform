# definición de proveedor Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.93.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

#Creación de Grupo de recursos principal
resource "azurerm_resource_group" "rg" {
  name     = var.resourcegroup
  location = var.location
}