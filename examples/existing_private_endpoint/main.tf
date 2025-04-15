##################################################
# Existing Private Endpoint Example
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

# Example: Use an existing private endpoint with a storage account
module "storage_with_existing_private_endpoint" {
  source = "../../modules/storage_account_firewall/"

  create_resource_group   = true
  resource_group_name     = "sa-existing-pe-rg"
  location                = "East US"
  
  create_storage_account  = true
  storage_account_name    = "saexistingpe${random_string.suffix.result}"
  
  allowed_ip_addresses    = var.allowed_public_ips
  
  # Use existing private endpoint configuration
  enable_private_endpoint       = true 
  use_existing_private_endpoint = true
  # Replace with your actual private endpoint ID
  existing_private_endpoint_id  = "/subscriptions/your-subscription-id/resourceGroups/network-rg/providers/Microsoft.Network/privateEndpoints/my-existing-pe"
  
  policy_name_prefix      = "existing-pe-policy"
  
  tags = {
    Environment = "Test"
    Purpose     = "Existing PE Example"
  }
}

# Example outputs
output "storage_account_id" {
  description = "The ID of the created storage account"
  value       = module.storage_with_existing_private_endpoint.storage_account_id
}

output "private_endpoint_id" {
  description = "The ID of the existing private endpoint being used"
  value       = module.storage_with_existing_private_endpoint.private_endpoint_id
} 