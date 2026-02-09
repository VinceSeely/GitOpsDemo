# La Crosse Dev - DevOps Demo

A demo project for the La Crosse Developer Meetup showcasing Infrastructure as Code with OpenTofu and CI/CD with GitHub Actions.

## What This Demo Shows

- **Azure Static Web Apps** (Free Tier) - Zero cost hosting
- **OpenTofu** - Open source Terraform alternative for IaC
- **GitHub Actions** - CI/CD pipelines with OIDC authentication
- **GitOps Promotion** - PR-based Dev → QA → Prod workflow
- **Infracost** - Infrastructure cost estimation
- **Secure Authentication** - OIDC federation (no stored credentials)

## Project Structure

```
├── src/                              # SPA web application
│   ├── index.html
│   ├── styles.css
│   ├── app.js
│   └── config.js                     # Generated at deploy time
├── infra/
│   ├── bootstrap-state-storage.sh   # Bash script for Linux/Mac/WSL
│   ├── bootstrap-state-storage.ps1  # PowerShell script for Windows
│   ├── bootstrap-state-storage.cmd  # Batch wrapper for Windows
│   ├── SETUP.md                      # Detailed setup guide
│   ├── BOOTSTRAP-SCRIPTS.md         # Bootstrap scripts reference
│   └── environments/
│       ├── dev/                      # Dev infrastructure
│       │   ├── main.tf
│       │   ├── backend.tf            # Terraform state config (committed)
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── qa/                       # QA infrastructure
│       │   └── .gitkeep              # backend.tf generated during promotion
│       └── prod/                     # Prod infrastructure
│           └── .gitkeep              # backend.tf generated during promotion
└── .github/
    └── workflows/
        ├── deploy-dev.yml            # Deploy dev on push to main
        ├── promote-to-qa.yml         # Auto-create PR for QA (generates backend.tf)
        ├── deploy-qa.yml             # Deploy QA when PR merged
        ├── promote.yml               # Manual trigger for prod PR (generates backend.tf)
        └── deploy-prod.yml           # Deploy prod when PR merged
```

## Promotion Flow (GitOps)

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  1. Push to main          2. Auto PR Created      3. Merge PR       │
│  ┌─────────┐             ┌─────────────────┐     ┌─────────┐       │
│  │   Dev   │ ──────────► │  PR: Dev → QA   │ ──► │   QA    │       │
│  │ Deploy  │  (auto)     │  (review)       │     │ Deploy  │       │
│  └─────────┘             └─────────────────┘     └─────────┘       │
│                                                        │            │
│                                                        │            │
│  4. Manual Trigger        5. PR Created          6. Merge PR       │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────┐       │
│  │ Promote to Prod │ ──► │  PR: QA → Prod  │ ──► │  Prod   │       │
│  │ (workflow)      │     │  (review)       │     │ Deploy  │       │
│  └─────────────────┘     └─────────────────┘     └─────────┘       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Azure Setup

1. **Create an Azure account** (free tier works)

2. **Bootstrap Terraform State Storage** - Run this script to set up state storage:

   **Linux/Mac/WSL:**
   ```bash
   cd infra
   chmod +x bootstrap-state-storage.sh
   ./bootstrap-state-storage.sh
   ```

   **Windows:**
   ```powershell
   cd infra
   .\bootstrap-state-storage.ps1
   ```
   Or simply double-click `bootstrap-state-storage.cmd`

   This creates the necessary Azure Storage for Terraform state management.

3. **Set up OIDC Authentication** for GitHub Actions (more secure than service principal credentials):

   See the detailed guide in [infra/SETUP.md](infra/SETUP.md) for complete instructions, or follow these quick steps:

   a. Go to Azure Portal → Azure AD → App Registrations → New registration
      - Name: `github-actions-vincepreso`

   b. Add Federated Credentials:
      - Go to Certificates & secrets → Federated credentials → Add credential
      - Select "GitHub Actions deploying Azure resources"
      - Organization: Your GitHub username/org
      - Repository: `vincepreso`
      - Entity type: Branch
      - Branch name: `main`

   c. Assign Azure permissions:
      ```bash
      az role assignment create \
        --assignee <your-client-id> \
        --role "Contributor" \
        --scope /subscriptions/<subscription-id>
      ```

### GitHub Setup

Add these secrets to your repository (Settings → Secrets and variables → Actions):

| Secret | Description | Example |
|--------|-------------|---------|
| `AZURE_CLIENT_ID` | Application (client) ID from App Registration | `12345678-1234-...` |
| `AZURE_TENANT_ID` | Directory (tenant) ID from Azure AD | `87654321-4321-...` |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID | `abcdef12-3456-...` |
| `INFRACOST_API_KEY` | Get from [infracost.io](https://www.infracost.io/) (free) | `ico-xxx...` |

**Note:** The old `AZURE_CREDENTIALS` secret is no longer needed with OIDC authentication!

### GitHub Environments

Create these environments in your repository settings (Settings → Environments):
- `dev`
- `qa` (optional: add required reviewers)
- `prod` (recommended: add required reviewers)

## Demo Flow for Presentation

### 1. Initial Dev Deployment
Push to main → auto-deploys to dev
```bash
git add . && git commit -m "Initial commit" && git push
```

### 2. Show Dev Site
Visit the dev URL showing "Hello, La Crosse Dev!"

### 3. Automatic QA Promotion
- A PR is automatically created: "Promote Dev to QA"
- Review the PR (show the diff)
- Merge the PR → QA deploys automatically

### 4. Show QA Site
Different URL, greeting shows "(QA)" suffix

### 5. Manual Production Promotion
```bash
# Or use GitHub UI: Actions → "Promote QA to Production" → Run workflow
gh workflow run promote.yml -f greeting_name="La Crosse Developers"
```
- A PR is created: "Promote QA to Production"
- Review with the team (show checklist)
- Merge → Production deploys

### 6. Show Production Site
Production URL with the final greeting!

## Workflows

| Workflow | Trigger | Action |
|----------|---------|--------|
| `deploy-dev.yml` | Push to main | Deploy dev environment |
| `promote-to-qa.yml` | Changes to `infra/environments/dev/` | Create PR for QA |
| `deploy-qa.yml` | Changes to `infra/environments/qa/` | Deploy QA environment |
| `promote.yml` | Manual dispatch | Create PR for Production |
| `deploy-prod.yml` | Changes to `infra/environments/prod/` | Deploy Production |

## Local Development

Open `src/index.html` in a browser - it works without a server.

To modify the greeting locally, edit `src/config.js`:
```javascript
window.APP_CONFIG = {
    greetingName: "Your Name Here",
    environment: "local",
    version: "1.0.0",
    deployTime: new Date().toISOString()
};
```

## Cost

**$0/month** - Azure Static Web Apps Free tier includes:
- 100 GB bandwidth/month
- 2 custom domains
- Free SSL certificates
- GitHub Actions integration

## Security & Best Practices

This project uses **OIDC authentication** instead of service principal credentials:

✅ **Benefits:**
- No credentials stored in GitHub secrets
- Federated identity with Azure AD
- Automatic credential rotation
- More secure than long-lived secrets
- Follows Azure best practices

🔒 **What Changed:**
- Old: `AZURE_CREDENTIALS` secret with JSON credentials
- New: Three separate secrets (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`)
- Backend configuration moved from CLI parameters to `backend.tf` files
- Explicit `ARM_USE_OIDC=true` in workflows

For more details, see the [Setup Guide](infra/SETUP.md).

---

Built with ❤️ for the La Crosse Developer Community
