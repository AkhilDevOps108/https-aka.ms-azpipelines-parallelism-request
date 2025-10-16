output "cdn_url" {
  value = azurerm_cdn_endpoint.cdn_endpoint.host_name
}

output "website_url" {
  value = azurerm_storage_account.storage.primary_web_endpoint
}
