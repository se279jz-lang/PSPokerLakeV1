# 07_validate-etl.ps1
# Run validation stored proc and show recent anomalies
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$instance = $config.config.InstanceName.ToString().Trim()
$database = $config.config.DatabaseName.ToString().Trim()

function Sql([string]$q){ & sqlcmd -S "(localdb)\$instance" -d $database -b -Q $q }

$runId = [guid]::NewGuid().ToString()
Write-Host "=== Running ETL validation (RunId=$runId) ==="
Sql "EXEC dbo.Validate_ETL @RunId = '$runId';"

Write-Host "=== Recent anomalies ==="
Sql "SELECT TOP 20 * FROM dbo.ETL_ValidationLog ORDER BY log_time DESC;"