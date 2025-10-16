output "cdn_url" {
  value = azurerm_cdn_endpoint.cdn_endpoint.endpoint_hostname
}

output "website_url" {
  value = azurerm_storage_account_static_website.static_site.primary_web_endpoint
}
