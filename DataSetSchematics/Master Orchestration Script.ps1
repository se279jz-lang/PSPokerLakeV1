# master-etl.ps1
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "..\PSPokerETL_V1.0\config.xml"),
    [string]$HistoryRoot = $null
)

Write-Host "=== Poker Hand History ETL Run ==="

# Load config and resolve history root if not provided
[xml]$config = Get-Content $ConfigPath
if (-not $HistoryRoot) { $HistoryRoot = $config.config.HistoryDirectory.ToString().Trim() }
$instanceName = $config.config.InstanceName.ToString().Trim()
$databaseName = $config.config.DatabaseName.ToString().Trim()
$server = "(localdb)\$instanceName"

# 1. Upload new files into Lake_* staging
Write-Host "Step 1: Uploading XML files into staging..."
$uploader = Join-Path $PSScriptRoot "..\PSPokerETL_V1.0\upload-files-to-db.ps1"
& $uploader -ConfigPath $ConfigPath -HistoryRoot $HistoryRoot

# 2. Run ETL stored procedures to shred XML into relational schema
Write-Host "Step 2: Shredding staging XML into relational schema..."
sqlcmd -S $server -d $databaseName -Q "EXEC dbo.Etl_ProcessUnprocessed;"

# 3. Quick metrics for sanity check
Write-Host "Step 3: Metrics snapshot..."
sqlcmd -S $server -d $databaseName -Q "
SELECT COUNT(*) AS Sessions FROM Sessions;
SELECT COUNT(*) AS Hands FROM Hands;
SELECT COUNT(*) AS Players FROM Players;
SELECT COUNT(*) AS Actions FROM Actions;
"

Write-Host "=== ETL Run Complete ==="

<# 
This “master script” ties together the assets we’ve been shaping so
 you don’t have to juggle multiple pieces manually.
 
 #>