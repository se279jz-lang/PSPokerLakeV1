# Load config.xml for consistent settings
[xml]$config = Get-Content "$PSScriptRoot\config.xml"

$instanceName = $config.config.InstanceName
$dataFilePath = "$PSScriptRoot\${databaseName}.mdf"
$logFilePath =  "$PSScriptRoot\${databaseName}.ldf"

# Create and start LocalDB instance
sqllocaldb create $instanceName
sqllocaldb start $instanceName

Write-Host "LocalDB instance '$instanceName' created"
