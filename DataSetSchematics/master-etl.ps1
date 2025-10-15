# master-etl.ps1
param(
    [string]$ConfigPath = ".\config.xml",
    [string]$HistoryRoot = ".\History"
)

Write-Host "=== Poker Hand History ETL Run ==="
write-host $HistoryRoot

# 1. Upload new files into Lake_* staging
Write-Host "Step 1: Uploading XML files into staging..."
.\upload-files-to-db.ps1 -ConfigPath $ConfigPath -HistoryRoot $HistoryRoot

# 2. Run ETL stored procedures to shred XML into relational schema
Write-Host "Step 2: Shredding staging XML into relational schema..."
sqlcmd -S "(localdb)\MSSQLLocalDB" -d PokerHistory -Q "EXEC dbo.Etl_ProcessUnprocessed;"

# 3. Quick metrics for sanity check
Write-Host "Step 3: Metrics snapshot..."
sqlcmd -S "(localdb)\MSSQLLocalDB" -d PokerHistory -Q "
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