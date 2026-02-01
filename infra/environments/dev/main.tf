# La Crosse Dev - DevOps Demo
# Azure Static Web App (Free Tier) - $0/month

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend will be configured via CLI for each environment
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-lacrossedev-${var.environment}"
  location = var.location

  tags = local.tags
}

# Azure Static Web App (Free Tier)
resource "azurerm_static_web_app" "main" {
  name                = "swa-lacrossedev-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku_tier            = "Free"
  sku_size            = "Free"

  tags = local.tags
}

locals {
  tags = {
    project     = "lacrosse-dev-demo"
    environment = var.environment
    managed_by  = "opentofu"
  }
}
