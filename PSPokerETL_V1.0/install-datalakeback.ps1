# Load config.xml for consistent settings
[xml]$config = Get-Content "$PSScriptRoot\config.xml"

$instanceName = $config.config.InstanceName
$databaseName = $config.config.DatabaseName
$dataFilePath = "$env:USERPROFILE\${databaseName}.mdf"

# Create and start LocalDB instance
sqllocaldb create $instanceName
sqllocaldb start $instanceName

# Build connection string
$server = "(localdb)\$instanceName"
$query = @"
CREATE DATABASE [$databaseName]
ON (NAME = N'$databaseName', FILENAME = N'$dataFilePath')
LOG ON (NAME = N'${databaseName}_log', FILENAME = N'$env:USERPROFILE\${databaseName}_log.ldf');
GO
USE [$databaseName];
GO
CREATE TABLE MnemonicArtefacts (
    id INT PRIMARY KEY IDENTITY,
    tag NVARCHAR(100),
    content NVARCHAR(MAX),
    timestamp DATETIME DEFAULT GETDATE()
);
GO
"@

# Run SQL query using sqlcmd
sqlcmd -S $server -d master -Q $query

Write-Host "LocalDB instance '$instanceName' created with database '$databaseName'."
Write-Host "Tournament source folder from config.xml: $TournamentFolder"
Write-Host "Connection string from config.xml: $SqlConnectionString"
