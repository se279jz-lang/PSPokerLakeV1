# 03_create-db-instance.ps1
# Ensure LocalDB instance exists and start it; use config for names/paths
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$instanceName = $config.config.InstanceName.ToString().Trim()
$databaseName = $config.config.DatabaseName.ToString().Trim()

$dataFilePath = Join-Path $env:USERPROFILE ("{0}.mdf" -f $databaseName)
$logFilePath = Join-Path $env:USERPROFILE ("{0}.ldf" -f $databaseName)

# Create/start LocalDB instance
Write-Host "Ensuring LocalDB instance '$instanceName'..."
sqllocaldb create $instanceName 2>$null | Out-Null
sqllocaldb start $instanceName

Write-Host "LocalDB instance '$instanceName' started. MDF/LDF target: $dataFilePath, $logFilePath"