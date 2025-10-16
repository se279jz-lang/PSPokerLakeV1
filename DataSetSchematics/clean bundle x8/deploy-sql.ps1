param(
    [string]$ConfigPath = "$PSScriptRoot\config.xml"
)

$ErrorActionPreference = "Stop"

# Load config
[xml]$config = Get-Content $ConfigPath
$instance = $config.config.InstanceName.ToString().Trim()
$database = $config.config.DatabaseName.ToString().Trim()
$sqlFolder = Join-Path $PSScriptRoot "..\sql"

# Normalize server instance for localdb
$serverInstance = "(localdb)\\$instance"

Write-Host "Deploying SQL scripts to $serverInstance / $database"

# Ensure SqlServer module available (best-effort, non-blocking)
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Write-Warning "SqlServer module not found. Invoke-Sqlcmd may not be available."
}

# Ensure migrations table exists
$ensureMigrations = @"
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SchemaMigrations')
BEGIN
  CREATE TABLE SchemaMigrations (
    Id INT IDENTITY PRIMARY KEY,
    ScriptName NVARCHAR(255) NOT NULL,
    AppliedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END
"@
Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -Query $ensureMigrations

# Apply scripts in order (numeric prefix expected)
Get-ChildItem -Path $sqlFolder -Filter "*.sql" | Sort-Object Name | ForEach-Object {
    $script = $_.Name
    $already = (Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -Query "SELECT COUNT(*) AS cnt FROM SchemaMigrations WHERE ScriptName = '$script'").cnt
    if (-not $already -or $already -eq 0) {
        Write-Host "Applying $script..."
        Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -InputFile $_.FullName
        Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -Query "INSERT INTO SchemaMigrations (ScriptName) VALUES ('$script')"
    } else {
        Write-Host "Skipping $script (already applied)"
    }
}
