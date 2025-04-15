# Azure Storage Account Firewall Module Examples

This directory contains examples for using the Azure Storage Account Firewall module in different scenarios.

## Example Scenarios

1. **Basic Example** (`./basic`)
   - Simple setup for a storage account with firewall rules
   - Good starting point for basic understanding of the module

2. **Private Endpoint Example** (`./private_endpoint`)
   - Shows how to create a storage account with a private endpoint
   - Includes configuration for storage subresources (blob and file)

3. **Existing Private Endpoint Example** (`./existing_private_endpoint`)
   - Demonstrates how to use an existing private endpoint with a storage account
   - Useful when you have a centrally managed private endpoint

## Running the Examples

1. Navigate to the example directory you want to run:
   ```
   cd examples/basic
   ```

2. Update the subscription ID and any resource IDs (such as subnet IDs) in the example to match your Azure environment.

3. Initialize Terraform:
   ```
   terraform init
   ```

4. Review the planned changes:
   ```
   terraform plan
   ```

5. Apply the changes:
   ```
   terraform apply
   ```

## Notes

- In all examples, make sure to replace placeholder values (especially subscription IDs and resource IDs) with real values from your environment.
- The `existing_private_endpoint` example assumes you already have a private endpoint created elsewhere that you want to use with the storage account. 