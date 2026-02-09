# Bootstrap script to create Azure Storage for Terraform state
# Run this ONCE before your first terraform deployment
# Usage: .\bootstrap-state-storage.ps1 [-SubscriptionId <subscription-id>]

param(
    [string]$SubscriptionId = ""
)

# Configuration
$RESOURCE_GROUP = "rg-laxdevgroupdemo-tfstate"
$STORAGE_ACCOUNT = "tfstatelaxdevgroupdemo"
$CONTAINER_NAME = "tfstate"
$LOCATION = "centralus"

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green $args }
function Write-Warning { Write-ColorOutput Yellow $args }
function Write-Error { Write-ColorOutput Red $args }

Write-Success "========================================"
Write-Success "Terraform State Storage Bootstrap"
Write-Success "========================================"
Write-Output ""

# Check if Azure CLI is installed
try {
    $azVersion = az --version 2>$null
    if (-not $azVersion) {
        throw
    }
} catch {
    Write-Error "Error: Azure CLI is not installed"
    Write-Output "Install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Login check
Write-Warning "Checking Azure login status..."
try {
    $accountInfo = az account show 2>$null | ConvertFrom-Json
    if (-not $accountInfo) {
        throw
    }
} catch {
    Write-Warning "Not logged in. Starting login process..."
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Login failed"
        exit 1
    }
}

# Set subscription if provided
if ($SubscriptionId -ne "") {
    Write-Warning "Setting subscription to: $SubscriptionId"
    az account set --subscription $SubscriptionId
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to set subscription"
        exit 1
    }
}

# Display current subscription
$currentAccount = az account show | ConvertFrom-Json
$currentSubName = $currentAccount.name
$currentSubId = $currentAccount.id

Write-Success "Current Subscription: $currentSubName ($currentSubId)"
Write-Output ""

# Confirm before proceeding
$confirmation = Read-Host "Continue with this subscription? (Y/N)"
if ($confirmation -notmatch "^[Yy]$") {
    Write-Warning "Aborted by user"
    exit 0
}

# Create resource group
Write-Warning "Creating resource group: $RESOURCE_GROUP"
$rgExists = az group show --name $RESOURCE_GROUP 2>$null
if ($rgExists) {
    Write-Success "Resource group already exists"
} else {
    az group create `
        --name $RESOURCE_GROUP `
        --location $LOCATION `
        --tags purpose=terraform-state project=laxdevgroupdemo

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Resource group created"
    } else {
        Write-Error "Failed to create resource group"
        exit 1
    }
}

# Create storage account
Write-Warning "Creating storage account: $STORAGE_ACCOUNT"
$saExists = az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP 2>$null
if ($saExists) {
    Write-Success "Storage account already exists"
} else {
    az storage account create `
        --name $STORAGE_ACCOUNT `
        --resource-group $RESOURCE_GROUP `
        --location $LOCATION `
        --sku Standard_LRS `
        --encryption-services blob `
        --https-only true `
        --allow-blob-public-access false `
        --tags purpose=terraform-state project=laxdevgroupdemo

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Storage account created"
    } else {
        Write-Error "Failed to create storage account"
        exit 1
    }
}

# Create blob container
Write-Warning "Creating blob container: $CONTAINER_NAME"
$containerExists = az storage container show `
    --name $CONTAINER_NAME `
    --account-name $STORAGE_ACCOUNT `
    --auth-mode login 2>$null

if ($containerExists) {
    Write-Success "Blob container already exists"
} else {
    az storage container create `
        --name $CONTAINER_NAME `
        --account-name $STORAGE_ACCOUNT `
        --auth-mode login

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Blob container created"
    } else {
        Write-Error "Failed to create blob container"
        exit 1
    }
}

# Enable versioning on the storage account
Write-Warning "Enabling versioning on storage account..."
az storage account blob-service-properties update `
    --account-name $STORAGE_ACCOUNT `
    --resource-group $RESOURCE_GROUP `
    --enable-versioning true

if ($LASTEXITCODE -eq 0) {
    Write-Success "Versioning enabled"
} else {
    Write-Warning "Failed to enable versioning (may already be enabled)"
}

Write-Output ""
Write-Success "========================================"
Write-Success "Bootstrap Complete!"
Write-Success "========================================"
Write-Output ""
Write-Warning "State Storage Configuration:"
Write-Output "  Resource Group:   $RESOURCE_GROUP"
Write-Output "  Storage Account:  $STORAGE_ACCOUNT"
Write-Output "  Container:        $CONTAINER_NAME"
Write-Output "  Location:         $LOCATION"
Write-Output ""
Write-Warning "Next Steps:"
Write-Output "1. Update your backend.tf files with these values"
Write-Output "2. For GitHub Actions, set up OIDC federation:"
Write-Output "   - Go to Azure Portal > Azure AD > App registrations"
Write-Output "   - Create or select your GitHub Actions service principal"
Write-Output "   - Add Federated credentials for GitHub"
Write-Output "3. Grant the service principal 'Storage Blob Data Contributor' role:"
Write-Output ""
Write-Output "   az role assignment create \"
Write-Output "     --role 'Storage Blob Data Contributor' \"
Write-Output "     --assignee <service-principal-client-id> \"
Write-Output "     --scope /subscriptions/$currentSubId/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
Write-Output ""
Write-Success "Done!"
