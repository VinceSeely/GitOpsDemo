# La Crosse Dev - DevOps Demo

A demo project for the La Crosse Developer Meetup showcasing Infrastructure as Code with OpenTofu and CI/CD with GitHub Actions.

## What This Demo Shows

- **Azure Static Web Apps** (Free Tier) - Zero cost hosting
- **OpenTofu** - Open source Terraform alternative for IaC
- **GitHub Actions** - CI/CD pipelines
- **GitOps Promotion** - PR-based Dev → QA → Prod workflow
- **Infracost** - Infrastructure cost estimation

## Project Structure

```
├── src/                              # SPA web application
│   ├── index.html
│   ├── styles.css
│   ├── app.js
│   └── config.js                     # Generated at deploy time
├── infra/
│   └── environments/
│       ├── dev/                      # Dev infrastructure
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── terraform.tfvars
│       │   └── backend.tfvars
│       ├── qa/                       # Empty - populated by PR
│       │   └── .gitkeep
│       └── prod/                     # Empty - populated by PR
│           └── .gitkeep
└── .github/
    └── workflows/
        ├── deploy-dev.yml            # Deploy dev on push to main
        ├── promote-to-qa.yml         # Auto-create PR for QA when dev changes
        ├── deploy-qa.yml             # Deploy QA when PR merged
        ├── promote.yml               # Manual trigger to create prod PR
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

1. Create an Azure account (free tier works)
2. Create a Service Principal for GitHub Actions:
   ```bash
   az ad sp create-for-rbac --name "github-actions-lacrosse-dev" \
     --role contributor \
     --scopes /subscriptions/{subscription-id} \
     --sdk-auth
   ```
3. Create a Storage Account for Terraform state:
   ```bash
   az group create --name rg-tfstate --location "Central US"
   az storage account create --name tfstatelacrossedev \
     --resource-group rg-tfstate --location "Central US" \
     --sku Standard_LRS
   az storage container create --name tfstate \
     --account-name tfstatelacrossedev
   ```

### GitHub Setup

Add these secrets to your repository:

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | JSON output from service principal creation |
| `TFSTATE_RESOURCE_GROUP` | `rg-tfstate` |
| `TFSTATE_STORAGE_ACCOUNT` | `tfstatelacrossedev` |
| `TFSTATE_CONTAINER` | `tfstate` |
| `INFRACOST_API_KEY` | Get from [infracost.io](https://www.infracost.io/) (free) |

### GitHub Environments

Create these environments in your repository settings:
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

---

Built with ❤️ for the La Crosse Developer Community
