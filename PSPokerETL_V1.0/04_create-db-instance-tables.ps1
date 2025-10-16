# Load config
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$SqlConnectionString = $config.config.ConnectionString
$tables = $config.config.historytable

write-host "$PSScriptRoot\config.xml"

Write-Host "Tables to create:"
foreach ($table in $tables) {
    Write-Host " - Lake_$($table.name.Trim())"
}

# Canonical schema
$canonicalSchema = @"
CREATE TABLE dbo.{0} (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FileName NVARCHAR(260) NOT NULL,
    XmlContent XML NOT NULL,
    UploadTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FileSize BIGINT NOT NULL,
    Sha256Hash CHAR(64) NOT NULL,
    OriginalCreationTime DATETIME2 NULL,
    OriginalLastWriteTime DATETIME2 NULL
)
"@

# Create each table
$connection = New-Object System.Data.SqlClient.SqlConnection $SqlConnectionString
$connection.Open()

foreach ($table in $tables) {
    $tableName = "Lake_" + $table.name.Trim()
    $createSql = [string]::Format($canonicalSchema, $tableName)
    $command = $connection.CreateCommand()
    $command.CommandText = $createSql

    try {
        $command.ExecuteNonQuery()
        Write-Host "✅ Table '$tableName' created successfully."
    } catch {
        Write-Warning "⚠️ Failed to create table '$tableName': $($_.Exception.Message)"
    }

}
$connection.Close()

