param(
    [string]$ConfigPath = ""
)

# Load config
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    [xml]$config = Get-Content "$PSScriptRoot\config.xml"
} else {
    [xml]$config = Get-Content $ConfigPath
}

$instanceName = $config.config.InstanceName.ToString().Trim()
$databaseName = $config.config.DatabaseName.ToString().Trim()
$tables = $config.config.historytable

Write-Host "Creating tables in '$databaseName' on (localdb)\$instanceName"

$server = "(localdb)\\$instanceName"
$fullQuery = "USE [$databaseName];`n"

$schema = @"
IF OBJECT_ID(N'dbo.{0}', 'U') IS NULL
BEGIN
CREATE TABLE dbo.{0} (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FileName NVARCHAR(260) NOT NULL,
    XmlContent XML NOT NULL,
    UploadTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FileSize BIGINT NOT NULL,
    Sha256Hash CHAR(64) NOT NULL,
    OriginalCreationTime DATETIME2 NULL,
    OriginalLastWriteTime DATETIME2 NULL,
    Processed BIT NOT NULL DEFAULT 0,
    SessionCode NVARCHAR(100) NULL
);
END
IF OBJECT_ID(N'dbo.{0}', 'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_{0}_Sha256Hash' AND object_id = OBJECT_ID(N'dbo.{0}'))
        ALTER TABLE dbo.{0} ADD CONSTRAINT [UQ_{0}_Sha256Hash] UNIQUE (Sha256Hash);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_{0}_SessionCode' AND object_id = OBJECT_ID(N'dbo.{0}'))
        ALTER TABLE dbo.{0} ADD CONSTRAINT [UQ_{0}_SessionCode] UNIQUE (SessionCode);
END
"@

foreach ($t in $tables) {
    $name = $t.name.ToString().Trim()
    $tableName = "Lake_$name"
    $fullQuery += [string]::Format($schema, $tableName) + "`n"
}

# Execute via sqlcmd
& sqlcmd -S $server -b -Q $fullQuery

Write-Host "Done."
