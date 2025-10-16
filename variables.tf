variable "resource_group_name" {
  type    = string
  default = "rg-static-webapp"
}

variable "storage_account_name" {
  type    = string
  default = "staticwebdemo123"  # must be globally unique
}

variable "prefix" {
  type    = string
  default = "staticdemo"
}

variable "location" {
  type    = string
  default = "eastus"
}
