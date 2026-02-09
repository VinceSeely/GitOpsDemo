# Infrastructure Setup Guide

This guide walks you through setting up the Terraform state storage and OIDC authentication for the vincepreso project.

## Prerequisites

- Azure CLI installed and configured
- Azure subscription with appropriate permissions
- Access to Azure AD to configure App Registrations

## Step 1: Bootstrap Terraform State Storage

Run this **ONCE** before your first deployment:

### Linux/Mac/WSL:
```bash
cd infra
chmod +x bootstrap-state-storage.sh
./bootstrap-state-storage.sh [optional-subscription-id]
```

### Windows (PowerShell):
```powershell
cd infra
.\bootstrap-state-storage.ps1 [-SubscriptionId <optional-subscription-id>]
```

### Windows (Command Prompt):
```cmd
cd infra
bootstrap-state-storage.cmd
```

This script will:
- Create resource group: `rg-vincepreso-tfstate`
- Create storage account: `tfstatevincepreso`
- Create blob container: `tfstate`
- Enable versioning for state file protection

**Note:** The script will prompt you to confirm your Azure subscription before proceeding.

## Step 2: Set Up OIDC Authentication for GitHub Actions

### 2.1 Create or Update Azure AD App Registration

1. Go to [Azure Portal](https://portal.azure.com) → Azure Active Directory → App registrations
2. Create a new app registration or select an existing one:
   - **Name:** `github-actions-vincepreso`
   - **Supported account types:** Accounts in this organizational directory only

### 2.2 Add Federated Credentials

1. In your App Registration, go to **Certificates & secrets** → **Federated credentials**
2. Click **Add credential** and select **GitHub Actions deploying Azure resources**
3. Configure the credential:
   - **Organization:** Your GitHub username or org (e.g., `vinceseely`)
   - **Repository:** `vincepreso`
   - **Entity type:** `Branch`
   - **GitHub branch name:** `main`
   - **Name:** `vincepreso-main-branch`
   - Click **Add**

4. Repeat for other environments if needed (qa, prod branches)

### 2.3 Assign Azure Permissions

Grant the service principal necessary permissions:

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get your App Registration's Client ID (from Azure Portal)
CLIENT_ID="your-app-client-id-here"

# Assign Contributor role to the subscription
az role assignment create \
  --assignee $CLIENT_ID \
  --role "Contributor" \
  --scope /subscriptions/$SUBSCRIPTION_ID

# Assign Storage Blob Data Contributor for state storage
az role assignment create \
  --assignee $CLIENT_ID \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-vincepreso-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatevincepreso
```

### 2.4 Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- `AZURE_CLIENT_ID`: Application (client) ID from your App Registration
- `AZURE_TENANT_ID`: Directory (tenant) ID from your App Registration
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID

**Remove these old secrets (no longer needed with OIDC):**
- ~~`AZURE_CREDENTIALS`~~ (delete if exists)
- ~~`TFSTATE_RESOURCE_GROUP`~~ (now hardcoded in backend.tf)
- ~~`TFSTATE_STORAGE_ACCOUNT`~~ (now hardcoded in backend.tf)
- ~~`TFSTATE_CONTAINER`~~ (now hardcoded in backend.tf)

## Step 3: Verify Local Setup (Optional)

Test your setup locally before running in GitHub Actions:

```bash
# Login to Azure
az login

# Set environment variables for OIDC
export ARM_CLIENT_ID="your-client-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_USE_OIDC=true

# Initialize and test
cd infra/environments/dev
tofu init
tofu plan -var="environment=dev" -var="greeting_name=Local Test"
```

## Architecture Overview

### State Storage Structure
```
rg-vincepreso-tfstate/
└── tfstatevincepreso/
    └── tfstate/
        ├── dev.terraform.tfstate
        ├── qa.terraform.tfstate
        └── prod.terraform.tfstate
```

### Backend Configuration Strategy

**Dev Environment:**
- `backend.tf` is committed to the repository
- Manually created and maintained

**QA Environment:**
- `backend.tf` is **auto-generated** during the promotion workflow
- Created when `promote-to-qa.yml` runs
- Only the `.gitkeep` file is committed initially

**Prod Environment:**
- `backend.tf` is **auto-generated** during the promotion workflow
- Created when `promote.yml` runs
- Only the `.gitkeep` file is committed initially

This approach ensures:
✅ Dev backend config is stable and committed
✅ QA/Prod backend configs are generated dynamically
✅ No risk of accidentally committing wrong environment configs
✅ GitOps promotion flow creates complete infrastructure configs

### OIDC Authentication Flow
```
GitHub Actions
    ↓ (OIDC Token)
Azure AD Federated Identity
    ↓ (Trusted)
Service Principal
    ↓ (Has Permissions)
Azure Resources
```

## Troubleshooting

### Error: "Failed to get existing workspaces"
- Ensure the service principal has "Storage Blob Data Contributor" role on the storage account
- Run the bootstrap script again to verify storage account setup

### Error: "AADSTS700016: Application not found"
- Verify `AZURE_CLIENT_ID` matches your App Registration
- Ensure Federated Credentials are configured correctly

### Error: "No subscription found"
- Verify `AZURE_SUBSCRIPTION_ID` is correct
- Ensure the service principal has Contributor access to the subscription

### Backend initialization fails
- Check that `backend.tf` exists in the environment directory
- Verify storage account name and resource group are correct
- Ensure you've run the bootstrap script first

## Security Best Practices

✅ **DO:**
- Use OIDC authentication (no stored credentials)
- Enable storage account versioning for state files
- Use separate state files per environment
- Implement least-privilege access for service principals
- Enable soft delete on the storage account

❌ **DON'T:**
- Store service principal secrets in GitHub
- Share state files between unrelated projects
- Skip the bootstrap script and manually create storage
- Use the same credentials for multiple projects

## Next Steps

After completing this setup:

1. Commit and push changes to trigger the workflow
2. Monitor the GitHub Actions run
3. Verify the deployment in Azure Portal
4. Test your deployed application

## Reference

- [TimePunchClock Terraform Setup](../TimePunchClock/Infra/dev/) - Working reference implementation
- [Azure OIDC for GitHub Actions](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [Terraform Azure Backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
