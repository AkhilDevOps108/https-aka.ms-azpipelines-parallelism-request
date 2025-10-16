terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0"
    }
  }
}

provider "azurerm" {
  features = {}
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  static_website {
    index_document = "index.html"
    error_404_document = "404.html"
  }
}

# Upload Files (local-exec only for demo)
resource "null_resource" "upload_site" {
  provisioner "local-exec" {
    command = <<EOT
      az storage blob upload-batch \
        --account-name ${azurerm_storage_account.storage.name} \
        --auth-mode login \
        -s ./website \
        -d '$web' \
        --overwrite
    EOT
  }
  depends_on = [azurerm_storage_account.storage]
}

# CDN Endpoint
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
    host_name = azurerm_storage_account.storage.primary_web_host
  }
}
