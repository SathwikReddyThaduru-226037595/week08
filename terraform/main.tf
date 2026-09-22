# SIT722 Week 08 infrastructure
# Creates: Resource Group, ACR, AKS (3 nodes), AcrPull link, Storage Account + 2 blob containers

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s_v2"
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}

# Random suffix so ACR and Storage names are globally unique
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

resource "azurerm_resource_group" "rg" {
  name     = "sit722-week08-rg"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = "koalatechacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "koalatech-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "koalatech${random_string.suffix.result}"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

# Lets AKS pull images from ACR (prevents ImagePullBackOff errors)
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

resource "azurerm_storage_account" "sa" {
  name                     = "koalatechsa${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container names match AZURE_STORAGE_CONTAINER_NAME in the Kubernetes manifests
resource "azurerm_storage_container" "student_photos" {
  name                  = "student-profile-photo"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "lecturer_photos" {
  name                  = "lecturer-profile-photo"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

output "AKS_RESOURCE_GROUP" {
  value = azurerm_resource_group.rg.name
}

output "AKS_CLUSTER_NAME" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "ACR_NAME" {
  value = azurerm_container_registry.acr.name
}

output "ACR_LOGIN_SERVER" {
  value = azurerm_container_registry.acr.login_server
}

output "storage_connection_string" {
  value     = azurerm_storage_account.sa.primary_connection_string
  sensitive = true
}
