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

# ---------------- FRONT DOOR (replaces CDN) ----------------

resource "azurerm_frontdoor" "fd" {
  name                = "${var.prefix}-frontdoor"
  resource_group_name = azurerm_resource_group.rg.name
  enforce_backend_pools_certificate_name_check = false

  frontend_endpoint {
    name                              = "${var.prefix}-frontend"
    host_name                         = "${var.prefix}-frontdoor.azurefd.net"
    custom_https_provisioning_enabled = false
  }

  backend_pool {
    name = "storage-backend"

    backend {
      host_header = azurerm_storage_account.storage.primary_web_host
      address     = azurerm_storage_account.storage.primary_web_host
      http_port   = 80
      https_port  = 443
      weight      = 50
      priority    = 1
    }

    load_balancing_name = "lb"
    health_probe_name   = "hp"
  }

  backend_pool_load_balancing {
    name = "lb"
  }

  backend_pool_health_probe {
    name = "hp"
    path = "/"
  }

  routing_rule {
    name               = "route1"
    accepted_protocols  = ["Http", "Https"]
    patterns_to_match   = ["/*"]
    frontend_endpoints  = ["${var.prefix}-frontend"]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = "storage-backend"
    }
  }
}

output "frontdoor_url" {
  value = azurerm_frontdoor.fd.frontend_endpoints[0].host_name
}
