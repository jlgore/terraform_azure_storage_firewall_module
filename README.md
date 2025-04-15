# Testing the Azure Storage Account Firewall Policy Module

This Terraform configuration provides examples for testing the Azure Storage Account Firewall Policy module in two scenarios:

1. Creating a new storage account with firewall policy
2. Applying firewall policy to an existing storage account

## How to test

### Step 1: Create a new storage account with policy

```bash
# Initialize terraform
terraform init

# Comment out the "existing_storage_with_firewall" module in main.tf for first run
# or set create_storage_account = true in the existing module

# Apply the configuration
terraform apply
```

### Step 2: Test with an existing storage account

```bash
# After the first run, uncomment the "existing_storage_with_firewall" module
# Set create_storage_account = false in the existing module
# Update the storage_account_name to match the one created in Step 1

# Apply the configuration again
terraform apply
```

## Expected Results

1. The first run will create:
   - A new resource group
   - A new storage account
   - A policy definition
   - A policy assignment at the storage account level

2. The second run will:
   - Use the existing storage account
   - Create a new policy definition
   - Create a new policy assignment for the existing storage account

## Validation Tests

1. Try to modify the storage account's firewall rules to add an IP that's not in the allowed list
   - This should be blocked by the policy

2. Add an IP to the allowed_ip_addresses list and apply again
   - This should succeed

3. Check in the Azure Portal that the network rules are properly applied
