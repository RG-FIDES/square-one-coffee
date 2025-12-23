# Shiny App Deployment Automation System - Initial Deployment Plan

**Date**: December 23, 2025  
**Target App**: Edmonton Neighborhood Explorer (shiny-1)  
**Deployment Strategy**: Dedicated public repo in RB-FIDES organization → Posit Cloud auto-deployment

---

## Objective

Create an automated deployment pipeline that extracts Shiny apps from the square-one-coffee mother repo, publishes them to dedicated RB-FIDES organization repos, and auto-deploys to Posit Cloud via GitHub Actions. Includes deployment registry, VSCode task integration, and enhanced devops-engineer persona.

---

## Implementation Steps

### Step 1: Create Deployment Automation Scripts

**Location**: `scripts/` directory

#### 1.1 Core R Functions (`scripts/deployment-functions.R`)

Create R functions for deployment automation:

- `create_standalone_repo(app_path, repo_name, org = "RB-FIDES")`
  - Extracts app + dependencies to temp directory
  - Validates app structure (app.R, data-provisioning.R, etc.)
  - Returns path to standalone deployment directory

- `bundle_database(app_path, db_source_path = "data-private/derived/global-data.sqlite")`
  - Copies SQLite database to `data-local/` subfolder
  - Updates database paths in app code
  - Validates database file exists and is readable

- `strip_development_comments(file_path)`
  - Removes implementation notes and "secret sauce" documentation
  - Keeps minimal functional comments
  - Preserves user-facing documentation

- `generate_user_guide_readme(app_name, description, live_url, metrics_info)`
  - Creates Option B documentation (user guide style)
  - Includes: app name, description, live deployment link, usage guide, metric definitions, SOC contact info
  - Returns formatted README.md content

- `deploy_to_github(local_path, repo_name, org = "RB-FIDES")`
  - Initializes Git repository
  - Commits all files
  - Creates remote repo via GitHub API (requires PAT token)
  - Pushes to RB-FIDES organization

- `configure_posit_deployment(app_path, app_name)`
  - Creates rsconnect configuration files
  - Sets up deployment metadata
  - Validates Posit Cloud credentials

#### 1.2 PowerShell Orchestrator (`scripts/ps1/deploy-app.ps1`)

ASCII-only PowerShell script (per Developer standards) that orchestrates deployment:

```powershell
# deploy-app.ps1
# Description: Orchestrate Shiny app deployment to dedicated GitHub repo and Posit Cloud
# Usage: powershell -File scripts/ps1/deploy-app.ps1 -AppPath "analysis/shiny-1" -RepoName "soc-app-1" -Action "create"

param(
    [Parameter(Mandatory=$true)]
    [string]$AppPath,
    
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("create", "update")]
    [string]$Action
)

# Features:
# - Calls R deployment functions
# - Error handling with detailed messages
# - Logging to ai/memory/log/deployment-YYYYMMDD-HHMMSS.log
# - Returns Exit Code 0 on success, non-zero on failure
# - Validates prerequisites (R installed, GitHub credentials, Posit credentials)
```

---

### Step 2: Create GitHub Actions Workflow Template

**Location**: `scripts/templates/deploy-shiny-workflow.yml`

Create GitHub Actions workflow for automatic deployment to Posit Cloud:

```yaml
name: Deploy to Posit Cloud

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup R
      uses: r-lib/actions/setup-r@v2
      with:
        r-version: '4.3.0'
    
    - name: Install system dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y libgdal-dev libproj-dev libgeos-dev
    
    - name: Install R packages
      run: |
        install.packages(c("shiny", "leaflet", "sf", "DBI", "RSQLite", "dplyr", "rsconnect"))
      shell: Rscript {0}
    
    - name: Authenticate with Posit Cloud
      env:
        RSCONNECT_TOKEN: ${{ secrets.RSCONNECT_TOKEN }}
        RSCONNECT_SECRET: ${{ secrets.RSCONNECT_SECRET }}
        RSCONNECT_SERVER: ${{ secrets.RSCONNECT_SERVER }}
        RSCONNECT_ACCOUNT: ${{ secrets.RSCONNECT_ACCOUNT }}
      run: |
        rsconnect::setAccountInfo(
          name = Sys.getenv("RSCONNECT_ACCOUNT"),
          token = Sys.getenv("RSCONNECT_TOKEN"),
          secret = Sys.getenv("RSCONNECT_SECRET"),
          server = Sys.getenv("RSCONNECT_SERVER")
        )
      shell: Rscript {0}
    
    - name: Deploy to Posit Cloud
      run: |
        rsconnect::deployApp(
          appDir = ".",
          appName = "${{ github.event.repository.name }}",
          forceUpdate = TRUE
        )
      shell: Rscript {0}
```

**Note**: This file gets copied to `.github/workflows/` in each dedicated repo during `create_standalone_repo()`

---

### Step 3: Create Deployment Registry and Documentation

#### 3.1 Deployment Registry (`ai/memory/deployed-apps.md`)

Create markdown table tracking all deployed apps:

```markdown
# Deployed Shiny Apps Registry

Last Updated: YYYY-MM-DD

| App Name | Source Path | Dedicated Repo | Posit Cloud URL | Last Deployment | Current Version |
|----------|-------------|----------------|-----------------|-----------------|-----------------|
| Neighborhood Explorer | analysis/shiny-1 | [soc-app-1](https://github.com/RB-FIDES/soc-app-1) | [Live App](https://connect.posit.cloud/...) | 2025-12-23 | v1.0.0 |

## Deployment Notes

### Neighborhood Explorer (soc-app-1)
- **Initial Deployment**: 2025-12-23
- **Database**: global-data.sqlite (266 KB, bundled)
- **Data Source**: Ellis pipeline (ellis-0 through ellis-last)
- **Update Frequency**: Manual on-demand
- **Public Access**: Yes (RB-FIDES public repo)
```

#### 3.2 User Guide README Template (`scripts/templates/user-guide-readme.md`)

Template for Option B documentation (user guide with minimal technical details):

```markdown
# {{APP_NAME}}

**Live Application**: [Launch App]({{LIVE_URL}})  
**Developed by**: [RB-FIDES](https://github.com/RB-FIDES)  
**Client**: Square One Coffee

---

## About This Application

{{APP_DESCRIPTION}}

## How to Use

{{USAGE_INSTRUCTIONS}}

### Available Metrics

{{METRIC_DEFINITIONS}}

### Interactive Features

{{FEATURE_LIST}}

## Data Sources

This application uses publicly available data:
- {{DATA_SOURCE_1}}
- {{DATA_SOURCE_2}}

**Data Snapshot Date**: {{SNAPSHOT_DATE}}

## Contact

For questions about this application or Square One Coffee partnership inquiries:
- **Email**: contact@rb-fides.com
- **Square One Coffee**: [squareonecoffee.com](https://squareonecoffee.com)

## Technical Information

**Built with**: R Shiny, Leaflet, Simple Features (sf)  
**Hosting**: Posit Cloud  
**License**: MIT

---

*This application is part of the Square One Coffee research partnership focused on data-driven business intelligence and community insights.*
```

#### 3.3 Deployment Guide (`guides/deployment-guide.md`)

Step-by-step guide for deploying new apps and updating existing apps:

```markdown
# Shiny App Deployment Guide

## Prerequisites

1. **GitHub Access**
   - Personal Access Token (PAT) with repo creation permissions
   - Member of RB-FIDES organization with write access

2. **Posit Cloud Account**
   - Account configured with rsconnect credentials
   - Token and secret stored as GitHub organization secrets

3. **Local Environment**
   - R installed with required packages
   - Git configured with GitHub authentication
   - PowerShell available

## Deploy New App (Manual Process)

### Step 1: Prepare App in Mother Repo

1. Ensure app is fully functional: `shiny::runApp("analysis/YOUR-APP")`
2. Run Ellis pipeline to generate fresh database (if app uses data)
3. Test all interactive features
4. Document any app-specific requirements

### Step 2: Create Standalone Deployment Package

1. Create temporary deployment directory
2. Copy app files (app.R, data-provisioning.R, etc.)
3. Bundle database into data-local/ subfolder
4. Update database paths in code
5. Strip development comments
6. Generate user guide README

### Step 3: Create Dedicated GitHub Repo

1. Initialize Git repository in deployment directory
2. Create .github/workflows/ directory
3. Copy deploy-shiny-workflow.yml template
4. Commit all files
5. Create remote repo in RB-FIDES organization (public)
6. Push to GitHub

### Step 4: Configure GitHub Secrets

Add organization secrets if not already configured:
- RSCONNECT_TOKEN
- RSCONNECT_SECRET
- RSCONNECT_SERVER
- RSCONNECT_ACCOUNT

### Step 5: Trigger Initial Deployment

1. Push commits to main branch
2. GitHub Actions workflow automatically triggers
3. Monitor deployment logs
4. Verify app is live on Posit Cloud

### Step 6: Update Deployment Registry

Add entry to `ai/memory/deployed-apps.md`:
- App name
- Source path in mother repo
- Dedicated repo URL
- Posit Cloud URL
- Deployment date
- Version

## Update Existing App

### Step 1: Make Changes in Mother Repo

1. Develop and test changes in `analysis/YOUR-APP/`
2. Regenerate database if data pipeline changed
3. Test locally

### Step 2: Sync to Dedicated Repo

1. Navigate to dedicated repo clone
2. Copy updated files from mother repo
3. Update version number
4. Commit changes with descriptive message

### Step 3: Deploy Update

1. Push to main branch
2. GitHub Actions automatically redeploys
3. Verify updates are live
4. Update deployment registry with new version and date

## Automated Process (Future)

Once manual process is validated, implement:
- VSCode tasks for one-click deployment
- Automated syncing between mother repo and dedicated repos
- Version tagging and release management
```

---

### Step 4: Add VSCode Deployment Tasks

**Location**: `.vscode/tasks.json`

Add new deployment tasks following existing task structure:

```json
{
  "label": "Deploy Shiny App - Create New Repo",
  "type": "shell",
  "command": "powershell",
  "args": [
    "-File",
    "${workspaceFolder}/scripts/ps1/deploy-app.ps1",
    "-AppPath",
    "${input:appPath}",
    "-RepoName",
    "${input:repoName}",
    "-Action",
    "create"
  ],
  "problemMatcher": [],
  "presentation": {
    "reveal": "always",
    "panel": "new"
  }
},
{
  "label": "Deploy Shiny App - Update Existing",
  "type": "shell",
  "command": "powershell",
  "args": [
    "-File",
    "${workspaceFolder}/scripts/ps1/deploy-app.ps1",
    "-AppPath",
    "${input:appPath}",
    "-RepoName",
    "${input:repoName}",
    "-Action",
    "update"
  ],
  "problemMatcher": [],
  "presentation": {
    "reveal": "always",
    "panel": "new"
  }
},
{
  "label": "Show Deployment Registry",
  "type": "shell",
  "command": "code",
  "args": [
    "${workspaceFolder}/ai/memory/deployed-apps.md"
  ],
  "problemMatcher": []
}
```

Add corresponding input variables:

```json
"inputs": [
  {
    "id": "appPath",
    "type": "promptString",
    "description": "Path to app directory (e.g., analysis/shiny-1)"
  },
  {
    "id": "repoName",
    "type": "promptString",
    "description": "Dedicated repo name (e.g., soc-app-1)"
  }
]
```

---

### Step 5: Update DevOps Engineer Persona

**Location**: `ai/personas/devops-engineer.md`

Add new sections to persona definition:

#### Addition 1: R/Shiny Deployment Expertise

Insert after existing "Tools/Capabilities" section:

```markdown
### R/Shiny Deployment Expertise
- **Posit Cloud Deployment**: rsconnect package for Shiny and Quarto publishing
- **shinyapps.io Integration**: Account management, authentication, deployment workflows
- **Self-hosted Shiny Server**: Open source and commercial deployment strategies
- **SQLite Database Bundling**: Strategies for embedding databases in Shiny apps vs cloud database connections
- **User-Facing Documentation Standards**: Option B documentation (user guide with usage instructions, metric definitions, minimal technical implementation details)
- **GitHub Actions for R**: CI/CD workflows for Shiny deployment, package testing, Quarto rendering
- **Deployment Registry Maintenance**: Tracking deployed apps, version management, rollback procedures
```

#### Addition 2: Data Science CI/CD Workflows

Insert after R/Shiny expertise section:

```markdown
### Data Science CI/CD Workflows
- **RAP (Reproducible Analytical Pipeline)**: UK Government Digital Service patterns for production-grade analysis pipelines
- **Scheduled Report Generation**: Cron jobs, GitHub Actions scheduled workflows for automated report updates
- **Quarto Publishing**: Multi-format output deployment (HTML, PDF, presentations) to GitHub Pages, Netlify, Quarto Pub
- **Data Refresh Strategies**: Automated ETL execution, data validation, pipeline orchestration
- **Static Site Deployment**: GitHub Pages, Netlify for report hosting and documentation
- **Environment Promotion**: Dev → Staging → Production workflows for data products
```

#### Addition 3: Update Main Responsibilities

Modify "Key Responsibilities" section to prioritize Shiny deployment:

```markdown
### Key Responsibilities (Updated)
- **PRIMARY: Shiny App Deployment Automation**: Extract apps from mother repo, publish to dedicated repos, auto-deploy to Posit Cloud
- **Deployment Registry Management**: Maintain accurate tracking of all deployed apps, versions, and update history
- **CI/CD Pipeline Design**: GitHub Actions workflows for Shiny apps, Quarto reports, and data pipelines
- **Environment Configuration**: Posit Cloud setup, rsconnect credentials, GitHub secrets management
- **User Documentation**: Generate client-facing documentation (Option B: user guide style) for deployed apps
- Infrastructure automation and orchestration
- Container orchestration and microservices
- Security and compliance implementation
- Monitoring and observability systems
```

---

## Clarification Questions Answered

### 1. Repository Structure & Hosting
- **Organization**: RB-FIDES organization
- **Visibility**: Public repos
- **Naming**: Sequential (`soc-app-1`, `soc-app-2`, etc.)

### 2. Deployment Automation Level
- **Posit Cloud**: GitHub Actions workflows for automatic deployment on push to main
- **Version Tracking**: Tag-based releases (v1.0.0, v1.1.0) in dedicated repos

### 3. Documentation Philosophy
- **Option B**: User Guide style
  - App name, description, live link
  - How to use the app
  - Metric definitions and feature explanations
  - SOC contact information
  - Minimal technical implementation details (no "secret sauce")

### 4. Data Sensitivity & Management
- **Database Inclusion**: Always bundle databases in dedicated repos
- **Data Refresh**: Static snapshot deployments (no live API connections)

### 5. Workflow Trigger
- **Preferred**: R function approach for flexibility
  - `deploy_shiny_app("analysis/shiny-1", repo_name = "soc-app-1", action = "create")`
- **Alternative**: VSCode task for UI convenience
  - Task prompts for app path and repo name
  - Calls PowerShell script which calls R functions

### 6. Tracking & Registry
- **Yes**: Maintain `ai/memory/deployed-apps.md`
  - Source path in mother repo
  - Dedicated repo URL
  - Posit Cloud app URL
  - Last deployment date
  - Version mapping
  - Deployment notes

---

## Technical Constraints & Considerations

### Database Deployment (shiny-1 specific)
- **Database**: `global-data.sqlite` (~266 KB)
- **Source**: `data-private/derived/global-data.sqlite` (not in Git)
- **Target**: `data-local/global-data.sqlite` (bundled with app)
- **Path Update Required**: Modify `data-provisioning.R` lines 16-22

### Code Modifications for Deployment

**Current code** (data-provisioning.R lines 16-22):
```r
# Connect to database (use path relative to project root)
db_path <- "../../data-private/derived/global-data.sqlite"
if (!file.exists(db_path)) {
  # If running from project root
  db_path <- "./data-private/derived/global-data.sqlite"
}
```

**Deployment code** (simplified path):
```r
# Connect to database (deployment path)
db_path <- "data-local/global-data.sqlite"

if (!file.exists(db_path)) {
  stop(paste0(
    "Database not found at: ", db_path, "\n",
    "Please ensure global-data.sqlite is present in data-local/ directory.\n",
    "This file is generated by running the Ellis pipeline."
  ))
}

message("Loading database from: ", db_path)
```

### Required Secrets (GitHub Organization Level)

Add to RB-FIDES organization secrets:
- `RSCONNECT_TOKEN` - Posit Cloud API token
- `RSCONNECT_SECRET` - Posit Cloud API secret
- `RSCONNECT_SERVER` - Posit Cloud server URL (typically `posit.cloud`)
- `RSCONNECT_ACCOUNT` - Posit Cloud account name

### R Package Dependencies (all on CRAN)
- shiny
- leaflet
- sf (requires GDAL, PROJ, GEOS - available on Posit Cloud)
- DBI
- RSQLite
- dplyr

---

## Implementation Approach

### Phase 1: Manual Implementation (Current)
1. Follow this plan step-by-step with human oversight
2. Deploy shiny-1 (Neighborhood Explorer) as proof of concept
3. Document any deviations or learnings
4. Validate end-to-end workflow

### Phase 2: AI-Supervised Automation (Future)
After manual validation:
1. Distill instructions for agent-driven deployment
2. Create enhanced devops-engineer persona with deployment capabilities
3. Enable natural language deployment commands
4. Implement monitoring and validation automation

---

## Success Criteria

### Immediate (Phase 1)
- [ ] shiny-1 app successfully deployed to soc-app-1 repo
- [ ] GitHub Actions workflow deploys app to Posit Cloud
- [ ] App is publicly accessible and fully functional
- [ ] Deployment registry updated with accurate information
- [ ] User guide README provides clear usage instructions

### Long-term (Phase 2)
- [ ] VSCode tasks enable one-click deployment
- [ ] DevOps persona can execute deployments autonomously
- [ ] Update workflow tested (mother repo → dedicated repo sync)
- [ ] Multiple apps deployed using standardized process
- [ ] Deployment process documented for team knowledge transfer

---

## Next Steps

1. **Setup Posit Cloud credentials** (if not already configured)
   - Create account on posit.cloud
   - Generate API token and secret
   - Test rsconnect::setAccountInfo() locally

2. **Setup GitHub organization access** (if not already configured)
   - Verify membership in RB-FIDES organization
   - Generate Personal Access Token with repo creation permissions
   - Test GitHub API access

3. **Begin manual deployment of shiny-1**
   - Follow Step 1: Prepare App in Mother Repo
   - Create standalone deployment directory
   - Bundle database and update paths
   - Test modified app locally

4. **Create dedicated repo and deploy**
   - Push to RB-FIDES/soc-app-1
   - Configure GitHub Actions workflow
   - Add organization secrets
   - Trigger initial deployment

5. **Document learnings**
   - Note any deviations from plan
   - Identify automation opportunities
   - Update deployment guide with insights

---

**Ready to begin manual implementation in separate chat session.**
