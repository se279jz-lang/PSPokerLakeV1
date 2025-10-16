<#
File: bootstrap-source-control.ps1
Purpose: Initialize Git, .gitignore, repo structure, and CI/CD scaffolding for the ETL pipeline.
Usage: .\bootstrap-source-control.ps1 -RepoName "PSPokerLakeV1" -RemoteUrl "https://github.com/you/PSPokerLakeV1.git"
#>
param(
  [string]$RepoName = "PSPokerLakeV1",
  [string]$RemoteUrl = ""
)

$ErrorActionPreference = "Stop"

# 1) Initialize Git
if (-not (Test-Path ".git")) {
  git init
}

# 2) .gitignore tuned for PowerShell + SQL + LocalDB + logs
$gitignore = @"
# OS
Thumbs.db
.DS_Store

# Logs and artifacts
logs/
*.log

# Local settings
*.user
*.suo

# Build/Temp
tmp/
temp/

# Data dumps
*.bak
*.dmp
*.mdf
*.ldf

# Secrets (ensure real secrets are external)
secrets.json
.env

# Python/R notebooks (if used)
.ipynb_checkpoints/
.Rproj.user/
"@
Set-Content -Path ".gitignore" -Value $gitignore -NoNewline

# 3) Repo structure
$dirs = @("scripts", "sql", "migrations", "docs", "ci")
foreach ($d in $dirs) {
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

# 4) Move curated assets (adjust paths as needed)
# PowerShell
Copy-Item -Path ".\install-datalake.ps1" -Destination ".\scripts\" -ErrorAction SilentlyContinue
Copy-Item -Path ".\upload-files-to-db.ps1" -Destination ".\scripts\" -ErrorAction SilentlyContinue
Copy-Item -Path ".\master-etl.ps1" -Destination ".\scripts\" -ErrorAction SilentlyContinue

# SQL
Copy-Item -Path ".\core-shared-schema.sql" -Destination ".\sql\" -ErrorAction SilentlyContinue
Copy-Item -Path ".\Etl_ProcessLakeTable.sql" -Destination ".\sql\" -ErrorAction SilentlyContinue
Copy-Item -Path ".\Etl_ProcessLakeTable-hands-actions-results-shredder.sql" -Destination ".\sql\" -ErrorAction SilentlyContinue
Copy-Item -Path ".\Validate_ETL.sql" -Destination ".\sql\" -ErrorAction SilentlyContinue
Copy-Item -Path ".\ETL_ValidationLog.sql" -Destination ".\sql\" -ErrorAction SilentlyContinue

# 5) Minimal CI skeleton (GitHub Actions example)
$workflow = @"
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  lint-and-dryrun:
    runs-on: windows-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: PowerShell lint (PSScriptAnalyzer)
        shell: pwsh
        run: |
          Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
          Invoke-ScriptAnalyzer -Path scripts -Recurse -Severity Error
      - name: SQL syntax check (basic)
        shell: pwsh
        run: |
          Get-ChildItem sql -Filter *.sql -Recurse | ForEach-Object {
            # Placeholder: add invocation to sqlcmd against LocalDB in CI environment if desired
            Write-Host "Syntax check placeholder for: $($_.FullName)"
          }
"@
$ciPath = ".\ci\workflow-ci.yml"
Set-Content -Path $ciPath -Value $workflow

# 6) README to explain the factory line and control panel
$readme = @"
# $RepoName

Production-grade ETL pipeline for poker hand histories:
- Staging integrity in Lake_* tables with uniqueness and processed flags.
- Core relational schema (Sessions/Players/Hands/Actions/Results + PlayersGlobal).
- ETL shredders with batch processing and idempotency.
- Validation procedure and ControlPanel.sql for health at a glance.
- Orchestrator to run end-to-end.

## Quick start
1. Create database (once): `sqlcmd -S (localdb)\MSSQLLocalDB -Q "IF DB_ID('PokerHistory') IS NULL CREATE DATABASE PokerHistory;"`
2. Apply schema: run `sql\core-shared-schema.sql`, then extensions if needed.
3. Ensure Lake_* tables: `scripts\install-datalake.ps1`.
4. Upload XMLs: `scripts\upload-files-to-db.ps1`.
5. ETL: `sql\Etl_ProcessLakeTable.sql` (proc), then `scripts\master-etl.ps1`.
6. Validate: `sql\Validate_ETL.sql` (proc), view `sql\ControlPanel.sql`.

## CI/CD
- Lints PowerShell scripts; placeholder for SQL validation.
- Extend with deployment steps to your SQL instance (e.g., sqlcmd).
"@
Set-Content -Path ".\README.md" -Value $readme

# 7) Initial commit and optional remote
git add .
git commit -m "Initialize ETL factory: scripts, sql, CI, README"
if ($RemoteUrl -ne "") {
  git branch -M main
  git remote add origin $RemoteUrl
  git push -u origin main
}

Write-Host "✅ Source control bootstrapped. Repo ready: $RepoName"
