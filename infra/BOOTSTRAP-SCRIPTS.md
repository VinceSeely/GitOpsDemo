# Bootstrap Scripts Reference

This directory contains three bootstrap scripts to create Azure Storage for Terraform state. Choose the one that matches your platform.

## Available Scripts

| Script | Platform | Description |
|--------|----------|-------------|
| `bootstrap-state-storage.sh` | Linux/Mac/WSL | Bash script for Unix-like systems |
| `bootstrap-state-storage.ps1` | Windows | PowerShell script (PowerShell 5.1+ or PowerShell Core) |
| `bootstrap-state-storage.cmd` | Windows | Batch file wrapper that auto-detects and runs PowerShell |

## Usage

### Linux, Mac, or WSL (Windows Subsystem for Linux)

```bash
cd infra
chmod +x bootstrap-state-storage.sh
./bootstrap-state-storage.sh
```

**With optional subscription ID:**
```bash
./bootstrap-state-storage.sh <your-subscription-id>
```

### Windows PowerShell

```powershell
cd infra
.\bootstrap-state-storage.ps1
```

**With optional subscription ID:**
```powershell
.\bootstrap-state-storage.ps1 -SubscriptionId "<your-subscription-id>"
```

### Windows Command Prompt

```cmd
cd infra
bootstrap-state-storage.cmd
```

**Or simply double-click** `bootstrap-state-storage.cmd` in File Explorer.

## What These Scripts Do

All three scripts perform the same operations:

1. ✅ Check if Azure CLI is installed
2. ✅ Verify you're logged into Azure (prompts login if needed)
3. ✅ Display your current Azure subscription
4. ✅ Ask for confirmation before proceeding
5. ✅ Create resource group: `rg-vincepreso-tfstate`
6. ✅ Create storage account: `tfstatevincepreso`
7. ✅ Create blob container: `tfstate`
8. ✅ Enable versioning on the storage account
9. ✅ Display next steps for OIDC setup

## Common Issues

### "Script not found" (Linux/Mac)
```bash
# Make sure you're in the infra directory
cd infra
pwd  # Should show .../vincepreso/infra

# Make the script executable
chmod +x bootstrap-state-storage.sh
```

### "Execution Policy" Error (Windows PowerShell)
```powershell
# Run PowerShell as Administrator and temporarily bypass policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\bootstrap-state-storage.ps1
```

Or use the .cmd wrapper which handles this automatically:
```cmd
bootstrap-state-storage.cmd
```

### "Azure CLI not found"
Download and install the Azure CLI:
- **Windows:** https://aka.ms/installazurecliwindows
- **Mac:** `brew install azure-cli`
- **Linux:** https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux

### "Not logged in" or Authentication Error
```bash
# Login to Azure
az login

# Verify login
az account show

# List available subscriptions
az account list --output table

# Set specific subscription
az account set --subscription "<subscription-id>"
```

### Storage Account Name Already Exists
If `tfstatevincepreso` is already taken globally (Azure storage names must be globally unique), edit the script and change:

**In .sh file:**
```bash
STORAGE_ACCOUNT="tfstatevincepreso"  # Change this
```

**In .ps1 file:**
```powershell
$STORAGE_ACCOUNT = "tfstatevincepreso"  # Change this
```

Then update the corresponding value in all `backend.tf` files in the environment directories.

## Security Notes

🔒 **Important Security Considerations:**

- These scripts use `az login` which respects your local Azure CLI authentication
- For CI/CD pipelines, use OIDC federation (not these scripts)
- The storage account is created with:
  - ✅ HTTPS-only access
  - ✅ TLS 1.2 minimum
  - ✅ No public blob access
  - ✅ Blob versioning enabled
  - ✅ Local redundancy (LRS)

## Next Steps

After running the bootstrap script successfully:

1. ✅ Verify the `backend.tf` files reference the correct storage account
2. ✅ Follow [SETUP.md](SETUP.md) to configure OIDC authentication
3. ✅ Add GitHub secrets for OIDC
4. ✅ Test your first deployment

## Script Maintenance

All three scripts should be kept in sync. If you modify the Azure resources created, update all three:

- `bootstrap-state-storage.sh` (Bash)
- `bootstrap-state-storage.ps1` (PowerShell)
- `bootstrap-state-storage.cmd` (Wrapper - rarely needs changes)

## Testing

To test without making changes:

**Bash:**
```bash
# Dry-run mode doesn't exist, but you can check what would be created
az group show --name rg-vincepreso-tfstate 2>/dev/null && echo "Already exists" || echo "Would create"
```

**PowerShell:**
```powershell
# Check if resources exist
az group show --name rg-vincepreso-tfstate 2>$null
if ($?) { Write-Host "Already exists" } else { Write-Host "Would create" }
```

## Support

If you encounter issues:

1. Check the [SETUP.md](SETUP.md) for detailed instructions
2. Verify Azure CLI is up to date: `az upgrade`
3. Check Azure permissions: You need Contributor role on the subscription
4. Review the [Troubleshooting section](SETUP.md#troubleshooting) in SETUP.md
