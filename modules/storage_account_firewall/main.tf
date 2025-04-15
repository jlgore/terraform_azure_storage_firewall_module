##################################################
# main.tf
##################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

# Create a resource group if create_resource_group is true
resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.this[0].name : var.resource_group_name
  
  # Get the storage account ID based on whether we're creating a new one or using an existing one
  storage_account_id = var.create_storage_account ? azurerm_storage_account.this[0].id : data.azurerm_storage_account.existing[0].id
  
  # Extract subscription_id and resource group from the storage account scope
  policy_scope = var.create_storage_account ? azurerm_storage_account.this[0].id : data.azurerm_storage_account.existing[0].id
  
  # Default private endpoint name if not specified
  private_endpoint_name = var.private_endpoint_name != "" ? var.private_endpoint_name : "${var.storage_account_name}-pe"
  
  # Determine the private endpoint ID based on whether we're creating a new one, using an existing one, or not using one
  private_endpoint_id = var.enable_private_endpoint && !var.use_existing_private_endpoint ? azurerm_private_endpoint.this[0].id : (
    var.use_existing_private_endpoint ? var.existing_private_endpoint_id : null
  )
}

# Reference an existing storage account if create_storage_account is false
data "azurerm_storage_account" "existing" {
  count               = var.create_storage_account ? 0 : 1
  name                = var.storage_account_name
  resource_group_name = local.resource_group_name
}

# Create a new storage account if create_storage_account is true
resource "azurerm_storage_account" "this" {
  count                     = var.create_storage_account ? 1 : 0
  name                      = var.storage_account_name
  resource_group_name       = local.resource_group_name
  location                  = var.location
  account_tier              = var.account_tier
  account_replication_type  = var.account_replication_type
  account_kind              = var.account_kind
  min_tls_version           = "TLS1_2"
  tags                      = var.tags
}

# Define the Azure policy definition to enforce IP restrictions
resource "azurerm_policy_definition" "storage_firewall_ips" {
  name         = "${var.policy_name_prefix}-storage-firewall-ip-restrictions"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Restrict Storage Account firewall to allowed IP addresses"
  description  = "This policy restricts Azure Storage Account firewall settings to only allow specified IP addresses"

  metadata = <<METADATA
    {
      "category": "Storage",
      "version": "1.0.0"
    }
METADATA

  policy_rule = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Storage/storageAccounts"
      },
      {
        "field": "Microsoft.Storage/storageAccounts/networkAcls.defaultAction",
        "equals": "Deny"
      },
      {
        "not": {
          "field": "Microsoft.Storage/storageAccounts/networkAcls.ipRules[*].value",
          "in": "[parameters('allowedIpAddresses')]"
        }
      }
    ]
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
POLICY_RULE

  parameters = <<PARAMETERS
{
  "allowedIpAddresses": {
    "type": "Array",
    "metadata": {
      "displayName": "Allowed IP Addresses",
      "description": "The list of allowed IP Addresses or CIDR ranges to be allowed in Storage Account firewall"
    },
    "defaultValue": []
  },
  "effect": {
    "type": "String",
    "metadata": {
      "displayName": "Effect",
      "description": "The effect determines what happens when the policy rule is evaluated to match"
    },
    "allowedValues": [
      "Audit",
      "Deny",
      "Disabled"
    ],
    "defaultValue": "Audit"
  }
}
PARAMETERS
}

# Assign the policy to the storage account or its parent scope
resource "azurerm_resource_policy_assignment" "storage_firewall_policy" {
  name                 = "${var.policy_name_prefix}-storage-firewall-assignment"
  resource_id          = local.policy_scope
  policy_definition_id = azurerm_policy_definition.storage_firewall_ips.id
  
  parameters = jsonencode({
    "allowedIpAddresses": {
      "value": var.allowed_ip_addresses
    },
    "effect": {
      "value": "Audit"
    }
  })

  # Add explicit dependency to ensure storage account is fully provisioned first
  depends_on = [
    azurerm_storage_account.this,
    azurerm_policy_definition.storage_firewall_ips
  ]
}

# Add IP rules to storage account if specified
resource "azurerm_storage_account_network_rules" "this" {
  count                = var.add_ip_rules ? 1 : 0
  storage_account_id   = local.storage_account_id
  default_action       = "Deny"
  bypass               = var.network_bypass
  
  # For ip_rules, only include IP addresses that are public (not 10.*, 172.16-31.*, 192.168.*)
  # Azure Storage accepts IPs in the format x.x.x.x or x.x.x.x/y where y is 0-30
  ip_rules             = [for ip in var.allowed_ip_addresses : trimspace(ip)]
  
  # Use subnet IDs for private network access
  virtual_network_subnet_ids = var.allowed_subnet_ids
  
  # Add explicit dependency to ensure storage account is fully provisioned first
  depends_on = [
    azurerm_storage_account.this,
    azurerm_resource_policy_assignment.storage_firewall_policy
  ]
}

# Reference an existing private endpoint if use_existing_private_endpoint is true
# Note: The provider doesn't support a data source for private endpoints, so we just use the ID
# data "azurerm_private_endpoint" "existing" {
#   count               = var.use_existing_private_endpoint ? 1 : 0
#   name                = basename(var.existing_private_endpoint_id)
#   resource_group_name = element(split("/resourceGroups/", var.existing_private_endpoint_id), 1)
# }

# Create private endpoint for the storage account (if enabled and not using existing)
resource "azurerm_private_endpoint" "this" {
  count               = var.enable_private_endpoint && !var.use_existing_private_endpoint ? 1 : 0
  name                = local.private_endpoint_name
  resource_group_name = local.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${local.private_endpoint_name}-connection"
    is_manual_connection           = var.is_manual_connection
    private_connection_resource_id = local.storage_account_id
    subresource_names              = var.private_endpoint_subresource_names
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_ids) > 0 ? [1] : []
    
    content {
      name                 = "${var.storage_account_name}-dns-zone-group"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }
}
