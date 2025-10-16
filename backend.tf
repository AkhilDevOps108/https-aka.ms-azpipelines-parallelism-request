terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate136425"   # use your existing one
    container_name       = "tfstate"
    key                  = "staticweb.tfstate"
  }
}
