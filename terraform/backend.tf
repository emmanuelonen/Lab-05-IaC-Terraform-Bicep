terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-eastus"
    storage_account_name = "sttfstateprod57240"
    container_name       = "tfstate"
    key                  = "lab5.prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
