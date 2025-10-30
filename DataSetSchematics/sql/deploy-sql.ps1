param(
    [string]$ConfigPath = "$PSScriptRoot\config.xml",
    [switch]$IncludeOptional
)

$ErrorActionPreference = "Stop"

# Load config
[xml]$config = Get-Content $ConfigPath
$instance = $config.config.InstanceName.ToString().Trim()
$database = $config.config.DatabaseName.ToString().Trim()
$sqlFolder = Join-Path $PSScriptRoot "..\sql"

# Normalize server instance for localdb
$serverInstance = "(localdb)\\$instance"

Write-Host "Deploying numbered SQL migrations from: $sqlFolder to $serverInstance / $database"

# Ensure SqlServer module available (best-effort)
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Write-Warning "SqlServer module not found. Invoke-Sqlcmd may not be available. Install-Module -Name SqlServer to enable."
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

# Find only files with numeric prefix like 01_..., 002-, etc. and sort by numeric prefix
$migrations = Get-ChildItem -Path $sqlFolder -Filter "*.sql" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^(\d{2,3})[_-].*\.sql$' } |
    ForEach-Object {
        $num = 0
        if ($_.Name -match '^(\d{2,3})[_-]') { $num = [int]$Matches[1] }
        [PSCustomObject]@{ File = $_; Ord = $num }
    } | Sort-Object Ord, @{Expression = {$_.File.Name}; Ascending = $true }

if (-not $migrations -or $migrations.Count -eq 0) {
    Write-Host "No numbered migration files found in $sqlFolder. Exiting."
    return
}

# Filter optional 09_* unless IncludeOptional flag set
if (-not $IncludeOptional) {
    $migrations = $migrations | Where-Object { $_.Ord -lt 9 }
}

foreach ($mig in $migrations) {
    $fileInfo = $mig.File
    $script = $fileInfo.Name

    # Check if already applied
    $alreadyRow = Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -Query "SELECT TOP 1 1 AS Applied FROM SchemaMigrations WHERE ScriptName = '$script'"
    $already = ($alreadyRow | Measure-Object).Count

    if ($already -gt 0) {
        Write-Host "Skipping $script (already applied)"
        continue
    }

    Write-Host "Applying $script..."
    try {
        Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -InputFile $fileInfo.FullName
        Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -Query "INSERT INTO SchemaMigrations (ScriptName) VALUES ('$script')"
        Write-Host "Applied $script"
    } catch {
        Write-Error ([string]::Format("Failed to apply {0}: {1}", $script, $_.Exception.Message))
        throw
    }
}

Write-Host "All numbered migrations processed. (Only files matching NN_*.sql were applied)"
