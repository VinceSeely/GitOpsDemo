output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "static_web_app_name" {
  description = "Name of the Static Web App"
  value       = azurerm_static_web_app.main.name
}

output "website_url" {
  description = "The URL to access the website"
  value       = "https://${azurerm_static_web_app.main.default_host_name}"
}

output "api_key" {
  description = "API key for deploying content to the Static Web App"
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}
