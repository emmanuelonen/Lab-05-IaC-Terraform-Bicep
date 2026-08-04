output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "The name of the main IaC resource group"
}

output "hub_vnet_id" {
  value       = azurerm_virtual_network.hub_vnet.id
  description = "The Resource ID of the Hub Virtual Network"
}

output "spoke_vnet_id" {
  value       = azurerm_virtual_network.spoke_vnet.id
  description = "The Resource ID of the Spoke Virtual Network"
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.law.workspace_id
  description = "The Workspace ID for Azure Monitor diagnostic integration"
}

output "storage_account_name" {
  value       = azurerm_storage_account.st.name
  description = "The name of the enterprise storage account"
}
