##################################################
# Basic example - Storage account with firewall
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
  default     = ["123.123.123.123", "42.42.42.42"]  # Replace with your actual IPs
}

# Random string for unique storage account names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Basic example for new storage account with firewall rules
module "new_storage_with_firewall" {
  source = "../../modules/storage_account_firewall/"

  create_resource_group   = true
  resource_group_name     = "sa-firewall-test-rg"
  location                = "East US"
  
  create_storage_account  = true
  storage_account_name    = "sabasictest${random_string.suffix.result}"
  
  allowed_ip_addresses    = var.allowed_public_ips
  
  policy_name_prefix      = "basic-policy"
  
  tags = {
    Environment = "Test"
    Purpose     = "Basic Example"
  }
}

# Example outputs to show important values
output "storage_account_id" {
  description = "The ID of the created storage account"
  value       = module.new_storage_with_firewall.storage_account_id
}

output "policy_assignment_id" {
  description = "The ID of the policy assignment for the storage account"
  value       = module.new_storage_with_firewall.policy_assignment_id
} 