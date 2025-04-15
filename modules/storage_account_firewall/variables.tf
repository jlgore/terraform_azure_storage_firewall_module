##################################################
# variables.tf
##################################################

variable "create_resource_group" {
  description = "Whether to create a resource group or use an existing one"
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "create_storage_account" {
  description = "Whether to create a new storage account or use an existing one"
  type        = bool
  default     = true
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Storage account kind (StorageV2, Storage, BlobStorage, etc.)"
  type        = string
  default     = "StorageV2"
}

variable "network_bypass" {
  description = "Specifies whether traffic is bypassed for Logging/Metrics/AzureServices"
  type        = list(string)
  default     = ["AzureServices"]
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses or CIDR blocks that are allowed to access the storage account"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs that are allowed to access the storage account"
  type        = list(string)
  default     = []
}

variable "add_ip_rules" {
  description = "Whether to add the IP rules directly to the storage account"
  type        = bool
  default     = true
}

variable "policy_name_prefix" {
  description = "Prefix for the policy name"
  type        = string
  default     = "sa-policy"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for the storage account"
  type        = bool
  default     = false
}

variable "use_existing_private_endpoint" {
  description = "Whether to use an existing private endpoint instead of creating a new one"
  type        = bool
  default     = false
}

variable "existing_private_endpoint_id" {
  description = "The ID of an existing private endpoint to use (required if use_existing_private_endpoint is true)"
  type        = string
  default     = ""
}

variable "private_endpoint_name" {
  description = "Name of the private endpoint resource (if not specified, storage account name with '-pe' suffix will be used)"
  type        = string
  default     = ""
}

variable "private_endpoint_subnet_id" {
  description = "ID of the subnet where the private endpoint will be created"
  type        = string
  default     = ""
}

variable "private_dns_zone_ids" {
  description = "List of private DNS zone IDs to link with the private endpoint"
  type        = list(string)
  default     = []
}

variable "private_endpoint_subresource_names" {
  description = "List of subresource names to enable with the private endpoint (blob, file, queue, table, etc.)"
  type        = list(string)
  default     = ["blob"]
}

variable "is_manual_connection" {
  description = "Whether the private endpoint connection requires manual approval"
  type        = bool
  default     = false
}

