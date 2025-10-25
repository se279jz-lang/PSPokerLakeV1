# 09_run-pipeline.ps1
<#
Purpose: Full ETL pipeline run — config‑driven, no hard‑coded values.
Usage:   .\09_run-pipeline.ps1 [-Since "2025-10-15T00:00:00Z"] [-BatchSize 500]
#>

param(
    [string]$Since,
    [int]$BatchSize = 500
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
[xml]$config = Get-Content "$root\config.xml"

$instance = $config.config.InstanceName
$database = $config.config.DatabaseName
$tables   = $config.config.historytables.historytable | ForEach-Object { "Lake_" + $_.name.Trim() }

Write-Host "=== Poker ETL Orchestrator ==="
Write-Host "Instance: $instance"
Write-Host "Database: $database"
Write-Host "Lake tables: $($tables -join ', ')"

# Step 1: Ensure DB
& "$root\02_create-db.ps1"

# Step 2: Ensure Lake_* tables
& "$root\04_create-db-instance-tables.ps1"

# Step 3: Upload XML files (with optional Since filter)
$uploadArgs = @{}
if ($Since) { $uploadArgs["Since"] = $Since }
& "$root\05_upload-files.ps1" @uploadArgs

# Step 4: Run ETL
& "$root\06_run-etl.ps1" -BatchSize $BatchSize

# Step 5: Validate
& "$root\07_validate-etl.ps1"

Write-Host "`n✅ ETL pipeline complete."
