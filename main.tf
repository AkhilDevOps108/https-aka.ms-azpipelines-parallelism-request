terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.102.0"
    }
  }
  required_version = ">=1.5.0"
}

provider "azurerm" {
  features {}
}

# ------------------  RESOURCES  ------------------

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# ✅ Correct static-website resource
resource "azurerm_storage_account_static_website" "static_site" {
  storage_account_id = azurerm_storage_account.storage.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

# CDN
resource "azurerm_cdn_profile" "cdn_profile" {
  name                = "${var.prefix}-cdn-profile"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = "${var.prefix}-cdn-endpoint"
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_cdn_profile.cdn_profile.location

  origin {
    name      = "storageorigin"
    host_name = azurerm_storage_account.storage.primary_blob_host
  }
}


