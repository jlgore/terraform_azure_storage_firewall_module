##################################################
# Private Endpoint Example
##################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Set your subscription ID here or use environment variables
  # subscription_id = "your-subscription-id"
}

variable "allowed_public_ips" {
  description = "List of public IP addresses to allow in the storage account firewall"
  type        = list(string)
  default     = ["123.123.123.123"]  # Replace with your actual IPs
}

# Random string for unique storage account names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Example: Storage account with private endpoint
module "storage_with_private_endpoint" {
  source = "../../modules/storage_account_firewall/"

  create_resource_group   = true
  resource_group_name     = "sa-pe-test-rg"
  location                = "East US"
  
  create_storage_account  = true
  storage_account_name    = "sapetest${random_string.suffix.result}"
  
  # IP restrictions can be used alongside private endpoints
  allowed_ip_addresses    = var.allowed_public_ips
  
  # Enable private endpoint
  enable_private_endpoint    = true
  # Replace this with your actual subnet ID
  private_endpoint_subnet_id = "/subscriptions/your-subscription-id/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/main-vnet/subnets/endpoint-subnet"
  
  # Optionally specify private DNS zone IDs if you have them
  # private_dns_zone_ids = [
  #   "/subscriptions/your-subscription-id/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  # ]
  
  # Specify which storage subresources to expose via private endpoint
  private_endpoint_subresource_names = ["blob", "file"]
  
  policy_name_prefix      = "pe-policy"
  
  tags = {
    Environment = "Test"
    Purpose     = "Private Endpoint Example"
  }
}

# Example outputs
output "storage_account_id" {
  description = "The ID of the created storage account"
  value       = module.storage_with_private_endpoint.storage_account_id
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = module.storage_with_private_endpoint.private_endpoint_id
}

output "private_endpoint_ip" {
  description = "The private IP address of the private endpoint"
  value       = module.storage_with_private_endpoint.private_endpoint_ip
} 