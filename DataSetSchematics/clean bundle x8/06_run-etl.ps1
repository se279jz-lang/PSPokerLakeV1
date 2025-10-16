# 06_run-etl.ps1
# Run ETL stored procedure for each Lake_* table defined in config.xml
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$instance = $config.config.InstanceName.ToString().Trim()
$database = $config.config.DatabaseName.ToString().Trim()
$lakes    = $config.config.historytable | ForEach-Object { "Lake_" + $_.name.Trim() }

function Sql([string]$q){ & sqlcmd -S "(localdb)\$instance" -d $database -b -Q $q }

$batchSize = 500
foreach ($lake in $lakes) {
  Write-Host "=== Processing $lake ==="
  Sql "EXEC dbo.Etl_ProcessLakeTable @LakeTable = N'$lake', @BatchSize = $batchSize;"
}
