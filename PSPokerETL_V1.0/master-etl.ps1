<#
File: master-etl.ps1
Purpose: End-to-end run: install/upgrade staging, upload files, run ETL, snapshot metrics, validate & log.
Usage: .\master-etl.ps1 -Instance "(localdb)\MSSQLLocalDB" -Database "PokerHistory" -HistoryRoot ".\History" -LakeTables "Lake_Tournament","Lake_Cash" -BatchSize 500
#>
param(
  [string]$Instance = "(localdb)\MSSQLLocalDB",
  [string]$Database = "PokerHistory",
  [string]$HistoryRoot = ".\History",
  [string[]]$LakeTables = @("Lake_Tournament","Lake_Cash"),
  [int]$BatchSize = 500
)

$ErrorActionPreference = "Stop"
function Sql([string]$q){ & sqlcmd -S $Instance -d $Database -b -Q $q }

Write-Host "=== Poker Hand History ETL Run ==="

# Install/upgrade Lake_* staging
Write-Host "Step 0: Ensuring Lake_* staging..."
& .\install-datalake.ps1 -Instance $Instance -Database $Database -Tables $LakeTables

# Upload files for each Lake table (choose per format if needed; here we demo tournament)
Write-Host "Step 1: Uploading XML files to Lake_Tournament..."
& .\upload-files-to-db.ps1 -Instance $Instance -Database $Database -HistoryRoot $HistoryRoot -LakeTable "Lake_Tournament"

# ETL: process all Lake_* tables
Write-Host "Step 2: ETL shredding..."
foreach ($lake in $LakeTables) {
  Write-Host "  → Processing $lake in batches of $BatchSize"
  Sql "EXEC dbo.Etl_ProcessLakeTable @LakeTable = N'$lake', @BatchSize = $BatchSize;"
}

# Metrics snapshot
Write-Host "Step 3: Metrics..."
Sql @"
SET NOCOUNT ON;
SELECT 'Sessions' AS name, COUNT(*) AS cnt FROM Sessions;
SELECT 'Players' AS name, COUNT(*) AS cnt FROM Players;
SELECT 'Hands'   AS name, COUNT(*) AS cnt FROM Hands;
SELECT 'Actions' AS name, COUNT(*) AS cnt FROM Actions;
SELECT 'Results' AS name, COUNT(*) AS cnt FROM Results;
SELECT 'GlobalPlayers' AS name, COUNT(*) AS cnt FROM PlayersGlobal;
"@

# Validation + logging
Write-Host "Step 4: Validation and logging..."
$runId = [guid]::NewGuid().ToString()
Sql "EXEC dbo.Validate_ETL @RunId = '$runId';"

Write-Host "=== ETL Run Complete ==="
