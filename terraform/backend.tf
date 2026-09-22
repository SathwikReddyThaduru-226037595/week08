# Remote state for the Week 08 infrastructure.
#
# This storage account is deliberately NOT managed by this configuration and
# lives in its own resource group, so that "terraform destroy" of the Week 08
# resource group cannot delete the state file it is currently using.
terraform {
  backend "azurerm" {
    resource_group_name  = "sit722-tfstate-rg"
    storage_account_name = "sit722tfstate226037595"
    container_name       = "tfstate"
    key                  = "week08.terraform.tfstate"
  }
}
