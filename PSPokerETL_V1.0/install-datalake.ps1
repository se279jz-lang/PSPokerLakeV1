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
"@

$tables = $config.config.historytable
$canonicalschema = @"
CREATE TABLE MnemonicArtefacts (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FileName NVARCHAR(260) NOT NULL,
    XmlContent XML NOT NULL,
    UploadTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FileSize BIGINT NOT NULL,
    Sha256Hash CHAR(64) NOT NULL,
    OriginalCreationTime DATETIME2 NULL,
    OriginalLastWriteTime DATETIME2 NULL
GO
"@
Write-Host "Tables to create:"
foreach ($table in $tables) {
    Write-Host " - Lake_$($table.name.Trim())"

    $tableName = "Lake_" + $table.name.Trim()
    $query += [string]::Format($canonicalSchema, $tableName)

}


# Run SQL query using sqlcmd
sqlcmd -S $server -d master -Q $query

Write-Host "LocalDB instance '$instanceName' created with database '$databaseName'."

