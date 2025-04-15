##################################################
# main.tf - Basic example
# See ./examples directory for more complex scenarios
##################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">=3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.0.0"
    }
  }
}

variable "azure_subscription_id" {
  type = string
}

variable "allowed_public_ips" {
  description = "List of public IP addresses to allow in the storage account firewall"
  type        = list(string)
  default     = ["123.123.123.123"]  # Add your default IPs here
}

variable "include_current_ip" {
  description = "Whether to include the current user's public IP in the storage account firewall"
  type        = bool
  default     = false
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  resource_provider_registrations = "none"  # Disable auto-registration
}

# Get current public IP address if include_current_ip is true
data "http" "current_ip" {
  count = var.include_current_ip ? 1 : 0
  url   = "https://api.ipify.org"
}

locals {
  # Combine the allowed IPs with the current IP if include_current_ip is true
  all_allowed_ips = var.include_current_ip ? concat(var.allowed_public_ips, ["${chomp(data.http.current_ip[0].response_body)}/32"]) : var.allowed_public_ips
}

# Random string to make storage account name unique
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "example" {
  name     = "snowflake-resource-group"
  location = "East US"
}

resource "azurerm_network_security_group" "example" {
  name                = "example-security-group"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_virtual_network" "example" {
  name                = "snowflake-subscription-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = "Production"
  }
}

# Create subnets separately to enable service endpoints
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

# Associate the security group with subnet2
resource "azurerm_subnet_network_security_group_association" "subnet2_nsg" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.example.id
}

# Basic usage: Create a new storage account with firewall policy
module "new_storage_with_firewall" {
  source = "./modules/storage_account_firewall/"

  create_resource_group   = true
  resource_group_name     = "sa-firewall-test-rg"
  location                = "East US"
  
  create_storage_account  = true
  storage_account_name    = "safirewalltest${random_string.suffix.result}"
  
  # Use the combined list of public IPs
  allowed_ip_addresses    = local.all_allowed_ips
  
  # Use subnet IDs for private network access - updated to use the new subnet resource
  allowed_subnet_ids      = [azurerm_subnet.subnet1.id]
  
  policy_name_prefix      = "test-policy"
  
  tags = {
    Environment = "Test"
    Purpose     = "Policy Testing"
  }
}

# Outputs
output "storage_account_id" {
  description = "The ID of the storage account"
  value       = module.new_storage_with_firewall.storage_account_id
}

output "policy_assignment_id" {
  description = "The ID of the policy assignment"
  value       = module.new_storage_with_firewall.policy_assignment_id
}
