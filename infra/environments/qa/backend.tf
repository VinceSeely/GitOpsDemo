# Terraform backend configuration for remote state
# State is stored in Azure Storage Account
# Run ../../bootstrap-state-storage.sh first to create the storage infrastructure

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-vincepreso-tfstate"
    storage_account_name = "tfstatevincepreso"
    container_name       = "tfstate"
    key                  = "qa.terraform.tfstate"
    use_oidc             = true
    # tenant_id and client_id are set via ARM_TENANT_ID and ARM_CLIENT_ID environment variables
  }
}
