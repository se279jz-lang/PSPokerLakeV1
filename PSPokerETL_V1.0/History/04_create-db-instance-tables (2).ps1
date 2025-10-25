param(
    [string]$ConfigPath = "",
    [string]$HistoryRoot = ""
)

# Load config (allow override)
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    [xml]$config = Get-Content "$PSScriptRoot\config.xml"
} else {
    [xml]$config = Get-Content $ConfigPath
}

$instanceName = $config.config.InstanceName.ToString().Trim()
$databaseName = $config.config.DatabaseName.ToString().Trim()
$SqlConnectionString = $config.config.ConnectionString.ToString().Trim()
$HistoryDirectory = $config.config.HistoryDirectory.ToString().Trim()
$tables = $config.config.historytable

Write-Host "Using config: $PSScriptRoot\config.xml"
Write-Host "Tables to create:"
foreach ($table in $tables) {
    Write-Host " - Lake_$($table.name.Trim())"
}

# Ensure LocalDB instance exists and is running
$instanceExists = $false
try {
    $info = sqllocaldb info $instanceName 2>$null
    if ($LASTEXITCODE -eq 0) { $instanceExists = $true }
} catch {
    $instanceExists = $false
}

if (-not $instanceExists) {
    Write-Host "Creating LocalDB instance '$instanceName'..."
    sqllocaldb create $instanceName | Out-Null
}

# Start instance if not running
$info = sqllocaldb info $instanceName 2>$null
if ($info -notmatch "State:\s*Running") {
    Write-Host "Starting LocalDB instance '$instanceName'..."
    sqllocaldb start $instanceName | Out-Null
}

# Determine MDF/LDF paths (place in user profile)
$dataFilePath = Join-Path $env:USERPROFILE ("{0}.mdf" -f $databaseName)
$logFilePath = Join-Path $env:USERPROFILE ("{0}.ldf" -f $databaseName)

# Build SQL: create DB if missing, then create tables idempotently
$server = "(localdb)\\$instanceName"

$createDb = @"
IF DB_ID(N'$databaseName') IS NULL
BEGIN
    CREATE DATABASE [$databaseName]
    ON (NAME = N'$databaseName', FILENAME = N'$dataFilePath')
    LOG ON (NAME = N'${databaseName}_log', FILENAME = N'$logFilePath');
END
"@

$fullQuery = $createDb + "`nUSE [$databaseName];`n"

# Canonical schema with idempotent checks and unique constraints
$canonicalSchema = @"
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
-- Add unique constraints if missing
IF OBJECT_ID(N'dbo.{0}', 'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_{0}_Sha256Hash' AND object_id = OBJECT_ID(N'dbo.{0}'))
    BEGIN
        ALTER TABLE dbo.{0} ADD CONSTRAINT [UQ_{0}_Sha256Hash] UNIQUE (Sha256Hash);
    END
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_{0}_SessionCode' AND object_id = OBJECT_ID(N'dbo.{0}'))
    BEGIN
        ALTER TABLE dbo.{0} ADD CONSTRAINT [UQ_{0}_SessionCode] UNIQUE (SessionCode);
    END
END
"@

foreach ($table in $tables) {
    $name = $table.name.Trim()
    $tableName = "Lake_$name"
    $fullQuery += [string]::Format($canonicalSchema, $tableName)
}

# Execute assembled SQL using sqlcmd (pipe via stdin)
Write-Host "Executing SQL on server '$server'..."

$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = 'sqlcmd'
$processInfo.RedirectStandardInput = $true
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true
$processInfo.UseShellExecute = $false
$processInfo.Arguments = "-S `"$server`" -b"

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $processInfo
$proc.Start() | Out-Null
$proc.StandardInput.WriteLine($fullQuery)
$proc.StandardInput.Close()

$stdout = $proc.StandardOutput.ReadToEnd()
$stderr = $proc.StandardError.ReadToEnd()
$proc.WaitForExit()

if ($proc.ExitCode -ne 0) {
    Write-Error "sqlcmd failed with exit code $($proc.ExitCode): $stderr"
    throw "Failed to create database/tables"
}

Write-Host "✅ Database and tables ensured for '$databaseName' on instance '$instanceName'."

