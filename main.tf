terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.90.0"
    }
  }
  required_version = ">=1.5.0"
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Storage Account for Static Website
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_static_website" "static_site" {
  storage_account_id = azurerm_storage_account.storage.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

# ✅ Modern CDN Front Door setup
resource "azurerm_cdn_frontdoor_profile" "fd_profile" {
  name                = "${var.prefix}-fd-profile"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_origin_group" "fd_origin_group" {
  name                     = "${var.prefix}-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  session_affinity_enabled = false
}

resource "azurerm_cdn_frontdoor_origin" "fd_origin" {
  name                          = "${var.prefix}-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.fd_origin_group.id
  host_name                     = azurerm_storage_account.storage.primary_web_host
  http_port                     = 80
  https_port                    = 443
  origin_host_header            = azurerm_storage_account.storage.primary_web_host
}

resource "azurerm_cdn_frontdoor_endpoint" "fd_endpoint" {
  name                     = "${var.prefix}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
}

resource "azurerm_cdn_frontdoor_route" "fd_route" {
  name                          = "${var.prefix}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.fd_origin_group.id
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  https_redirect_enabled        = true
  forwarding_protocol           = "MatchRequest"
  link_to_default_domain        = true
}

# Outputs
output "frontdoor_url" {
  value = azurerm_cdn_frontdoor_endpoint.fd_endpoint.host_name
}

output "storage_website_url" {
  value = azurerm_storage_account_static_website.static_site.primary_web_endpoint
}
