variable "k8slocation" {
  default = "France Central"
}

# Cluster AKS
resource "azurerm_kubernetes_cluster" "caso2" {
  name                = "aks-caso2"
  location            = var.k8slocation
  resource_group_name = azurerm_resource_group.caso2.name
  dns_prefix          = "caso2unir"
  kubernetes_version  = "1.28.5"
  sku_tier            = "Standard"

  # Grupo de Noodos principal
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  # Gestión de identidades administrada por Azure
  identity {
    type = "SystemAssigned"
  }

  # Habilitar RBAC
  role_based_access_control_enabled = true

  tags = {
    Environment = "Dev/Test"
  }
}

# Registrar salida del certificado de autenticación al cluster de AKS
output "client_certificate" {
  value     = azurerm_kubernetes_cluster.caso2.kube_config.0.client_certificate
  sensitive = true
}

# Registrar KUBECONFIG de acceso al cluster
output "kube_config" {
  value = azurerm_kubernetes_cluster.caso2.kube_config_raw

  sensitive = true
}

# Configurar RBAC acceso Azure de Identidad administrada para permitir usar imagenes del ACR privado
resource "azurerm_role_assignment" "k8s_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.caso2.kubelet_identity[0].object_id
}