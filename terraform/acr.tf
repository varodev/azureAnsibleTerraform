resource "azurerm_container_registry" "acr" {
  name                          = "unirregistry"
  resource_group_name           = var.resourcegroup
  location                      = var.location
  sku                           = "Standard"
  public_network_access_enabled = true
  anonymous_pull_enabled        = false
  admin_enabled                 = true
}