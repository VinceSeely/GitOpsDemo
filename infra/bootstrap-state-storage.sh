#!/bin/bash
# Bootstrap script to create Azure Storage for Terraform state
# Run this ONCE before your first terraform deployment
# Usage: ./bootstrap-state-storage.sh [subscription-id]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="rg-vincepreso-tfstate"
STORAGE_ACCOUNT="tfstatevincepreso"
CONTAINER_NAME="tfstate"
LOCATION="centralus"
SUBSCRIPTION_ID="${1:-}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Terraform State Storage Bootstrap${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Login check
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in. Starting login process...${NC}"
    az login
fi

# Set subscription if provided
if [ -n "$SUBSCRIPTION_ID" ]; then
    echo -e "${YELLOW}Setting subscription to: $SUBSCRIPTION_ID${NC}"
    az account set --subscription "$SUBSCRIPTION_ID"
fi

# Display current subscription
CURRENT_SUB=$(az account show --query name -o tsv)
CURRENT_SUB_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}Current Subscription: $CURRENT_SUB ($CURRENT_SUB_ID)${NC}"
echo ""

# Confirm before proceeding
read -p "Continue with this subscription? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Aborted by user${NC}"
    exit 1
fi

# Create resource group
echo -e "${YELLOW}Creating resource group: $RESOURCE_GROUP${NC}"
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${GREEN}Resource group already exists${NC}"
else
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --tags purpose=terraform-state project=vincepreso
    echo -e "${GREEN}Resource group created${NC}"
fi

# Create storage account
echo -e "${YELLOW}Creating storage account: $STORAGE_ACCOUNT${NC}"
if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${GREEN}Storage account already exists${NC}"
else
    az storage account create \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --encryption-services blob \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --tags purpose=terraform-state project=vincepreso
    echo -e "${GREEN}Storage account created${NC}"
fi

# Create blob container
echo -e "${YELLOW}Creating blob container: $CONTAINER_NAME${NC}"
if az storage container show \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login &> /dev/null; then
    echo -e "${GREEN}Blob container already exists${NC}"
else
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login
    echo -e "${GREEN}Blob container created${NC}"
fi

# Enable versioning on the storage account
echo -e "${YELLOW}Enabling versioning on storage account...${NC}"
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --enable-versioning true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Bootstrap Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}State Storage Configuration:${NC}"
echo "  Resource Group:   $RESOURCE_GROUP"
echo "  Storage Account:  $STORAGE_ACCOUNT"
echo "  Container:        $CONTAINER_NAME"
echo "  Location:         $LOCATION"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Update your backend.tf files with these values"
echo "2. For GitHub Actions, set up OIDC federation:"
echo "   - Go to Azure Portal > Azure AD > App registrations"
echo "   - Create or select your GitHub Actions service principal"
echo "   - Add Federated credentials for GitHub"
echo "3. Grant the service principal 'Storage Blob Data Contributor' role:"
echo ""
echo "   az role assignment create \\"
echo "     --role 'Storage Blob Data Contributor' \\"
echo "     --assignee <service-principal-client-id> \\"
echo "     --scope /subscriptions/$CURRENT_SUB_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
echo ""
echo -e "${GREEN}Done!${NC}"
