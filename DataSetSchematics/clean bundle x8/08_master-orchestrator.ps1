# 08_master-orchestrator.ps1
<#
Purpose: Full ETL pipeline run — from DB creation to validation.
Usage: .\08_master-orchestrator.ps1
#>

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
[xml]$config = Get-Content "$root\config.xml"

$instance = $config.config.InstanceName.ToString().Trim()
$database = $config.config.DatabaseName.ToString().Trim()
$tables   = $config.config.historytable | ForEach-Object { "Lake_" + $_.name.Trim() }

Write-Host "=== Poker ETL Orchestrator ==="
Write-Host "Instance: $instance"
Write-Host "Database: $database"
Write-Host "Lake tables: $($tables -join ', ')"

# Step 1: Create DB if missing
Write-Host "`n[Step 1] Ensuring database..."
& "$root\02_create-db.ps1"

# Step 2: Ensure Lake_* tables
Write-Host "`n[Step 2] Ensuring Lake_* staging tables..."
& "$root\04_create-db-instance-tables.ps1"

# Step 3: Upload XML files
Write-Host "`n[Step 3] Uploading XML files..."
& "$root\05_upload-files.ps1"

# Step 4: Run ETL
Write-Host "`n[Step 4] Running ETL shredders..."
& "$root\06_run-etl.ps1"

# Step 5: Validate
Write-Host "`n[Step 5] Validating ETL output..."
& "$root\07_validate-etl.ps1"

Write-Host "`n? ETL pipeline complete."