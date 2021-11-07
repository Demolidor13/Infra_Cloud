terraform {
    required_providers {
      azurerm = {
          source = "hashicorp/azurerm"
          version = "2.05"
      }
    }
}

provider "azurerm" {
  features {

  }
}

resource "azurerm_resource_group" "rg_k8s" {
  location = "eastus"
  name = "rg_k8s"
}

resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg_k8s.location
  resource_group_name = azurerm_resource_group.rg_k8s.name
  dns_prefix          = "aks-cluster"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2_v2"
  }

  service_principal {
    client_id = "94b25701-394f-4a26-ab6a-c9e1338ae652"
    client_secret = "oG5lIqqU9DpFA-9dwSnJPZYu1_T2dXwPtp"
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
  }

  tags = {
    Environment = "Production"
  }
}

# Only necessary when you need a private container registry

# resource "azurerm_container_registry" "acr-aula-infra" {
#   name                = "aulainfraacr"
#   resource_group_name = azurerm_resource_group.rg-aula-infra.name
#   location            = azurerm_resource_group.rg-aula-infra.location
#   sku                 = "Basic"
#   admin_enabled       = false
# }

# data "azuread_service_principal" "aks_principal" {
#     application_id = var.client
# }

# resource "azurerm_role_assignment" "acrpull-aula-infra" {
#   scope = azurerm_container_registry.acr-aula-infra.id
#   role_definition_name = "AcrPull"
#   principal_id = data.azuread_service_principal.aks_principal.id
#   skip_service_principal_aad_check = true
# }