# Azure Storage Account Firewall Policy Module

This Terraform module helps manage Azure Storage Account Firewalls at scale using Azure Policy. It allows you to:

1. Create a new storage account or use an existing one
2. Define and enforce a list of allowed IP addresses via Azure Policy
3. Optionally apply network rules directly to the storage account

## Features

- Conditional creation of a resource group and storage account
- Custom Azure Policy to enforce that only specified IP addresses are allowed in firewall rules
- Policy assigned at the storage account level
- Option to directly apply network rules to storage accounts
- Support for Azure Private Endpoints to securely access storage from your VNet
- Flexibility to create new private endpoints or use existing ones

## Usage

### Create a new storage account with firewall policy

```hcl
module "storage_firewall" {
  source = "./modules/azure-storage-firewall-policy"

  create_resource_group   = true
  resource_group_name     = "my-storage-rg"
  location                = "East US"
  
  create_storage_account  = true
  storage_account_name    = "mystorageaccount"
  
  allowed_ip_addresses    = ["203.0.113.0/24", "198.51.100.10"]
  
  policy_name_prefix      = "my-org"
  
  tags = {
    Environment = "Production"
    Owner       = "Cloud Team"
  }
}
```

### Use an existing storage account with firewall policy

```hcl
module "storage_firewall" {
  source = "./modules/azure-storage-firewall-policy"

  create_resource_group   = false
  resource_group_name     = "existing-rg"
  
  create_storage_account  = false
  storage_account_name    = "existingstorageaccount"
  
  allowed_ip_addresses    = ["203.0.113.0/24", "198.51.100.10"]
  
  policy_name_prefix      = "my-org"
}
```

### Create a storage account with private endpoint

```hcl
module "storage_with_private_endpoint" {
  source = "./modules/azure-storage-firewall-policy"

  create_resource_group   = true
  resource_group_name     = "my-storage-pe-rg"
  location                = "East US"
  
  create_storage_account  = true
  storage_account_name    = "mystoragepe"
  
  # IP restrictions can be used alongside private endpoints
  allowed_ip_addresses    = ["203.0.113.0/24"]
  
  # Enable private endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/main-vnet/subnets/endpoint-subnet"
  
  # Optionally, link to private DNS zones
  private_dns_zone_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  ]
  
  # Specify which storage subresources to expose
  private_endpoint_subresource_names = ["blob", "file"]
  
  policy_name_prefix = "my-org"
  
  tags = {
    Environment = "Production"
    Owner       = "Cloud Team"
  }
}
```

### Use an existing private endpoint with a storage account

```hcl
module "storage_with_existing_private_endpoint" {
  source = "./modules/azure-storage-firewall-policy"

  create_resource_group   = true
  resource_group_name     = "my-storage-rg"
  location                = "East US"
  
  create_storage_account  = true
  storage_account_name    = "mystorage"
  
  allowed_ip_addresses    = ["203.0.113.0/24"]
  
  # Use existing private endpoint instead of creating a new one
  enable_private_endpoint        = true
  use_existing_private_endpoint  = true
  existing_private_endpoint_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/privateEndpoints/existing-pe"
  
  policy_name_prefix = "my-org"
  
  tags = {
    Environment = "Production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| azurerm | >= 3.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_resource_group | Whether to create a resource group or use an existing one | `bool` | `false` | no |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region where resources will be created | `string` | `"East US"` | no |
| create_storage_account | Whether to create a new storage account or use an existing one | `bool` | `true` | no |
| storage_account_name | Name of the storage account | `string` | n/a | yes |
| account_tier | Storage account tier (Standard or Premium) | `string` | `"Standard"` | no |
| account_replication_type | Storage account replication type (LRS, GRS, RAGRS, ZRS) | `string` | `"LRS"` | no |
| account_kind | Storage account kind (StorageV2, Storage, BlobStorage, etc.) | `string` | `"StorageV2"` | no |
| network_bypass | Specifies whether traffic is bypassed for Logging/Metrics/AzureServices | `list(string)` | `["AzureServices"]` | no |
| allowed_ip_addresses | List of IP addresses or CIDR blocks that are allowed to access the storage account | `list(string)` | `[]` | no |
| allowed_subnet_ids | List of subnet IDs that are allowed to access the storage account | `list(string)` | `[]` | no |
| add_ip_rules | Whether to add the IP rules directly to the storage account | `bool` | `true` | no |
| policy_name_prefix | Prefix for the policy name | `string` | `"sa-policy"` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |
| enable_private_endpoint | Whether to create a private endpoint for the storage account | `bool` | `false` | no |
| use_existing_private_endpoint | Whether to use an existing private endpoint instead of creating a new one | `bool` | `false` | no |
| existing_private_endpoint_id | The ID of an existing private endpoint to use (required if use_existing_private_endpoint is true) | `string` | `""` | no |
| private_endpoint_name | Name of the private endpoint resource (if not specified, storage account name with '-pe' suffix will be used) | `string` | `""` | no |
| private_endpoint_subnet_id | ID of the subnet where the private endpoint will be created | `string` | `""` | no |
| private_dns_zone_ids | List of private DNS zone IDs to link with the private endpoint | `list(string)` | `[]` | no |
| private_endpoint_subresource_names | List of subresource names to enable with the private endpoint (blob, file, queue, table, etc.) | `list(string)` | `["blob"]` | no |
| is_manual_connection | Whether the private endpoint connection requires manual approval | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_name | The name of the resource group |
| storage_account_id | The ID of the storage account |
| policy_definition_id | The ID of the policy definition |
| policy_assignment_id | The ID of the policy assignment |
| private_endpoint_id | The ID of the private endpoint (if enabled) |
| private_endpoint_ip | The private IP address of the private endpoint (if enabled) |
| private_endpoint_fqdn | The fully qualified domain name of the private endpoint (if enabled and DNS zone group configured) |
