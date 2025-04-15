##################################################
# outputs.tf
##################################################

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = local.storage_account_id
}

output "policy_assignment_id" {
  description = "The ID of the policy assignment for the storage account"
  value       = azurerm_resource_policy_assignment.storage_firewall_policy.id
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint (if enabled)"
  value       = local.private_endpoint_id
}

output "private_endpoint_ip" {
  description = "The private IP address of the private endpoint (if enabled)"
  value       = var.enable_private_endpoint && !var.use_existing_private_endpoint ? try(azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address, null) : null
}

output "private_endpoint_fqdn" {
  description = "The fully qualified domain name of the private endpoint (if enabled and DNS zone group configured)"
  value       = var.enable_private_endpoint && !var.use_existing_private_endpoint && length(var.private_dns_zone_ids) > 0 ? try(azurerm_private_endpoint.this[0].custom_dns_configs[0].fqdn, null) : null
} 