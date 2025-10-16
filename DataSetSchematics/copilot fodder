📂 Proposed Clean Bundle (Config‑Driven)
01_create-config.ps1
Scans HISTORY subfolders.

Writes config.xml with <historytable name="…"/> entries.

Defines InstanceName, DatabaseName, ConnectionString. (You already have this — keep as is.)

02_create-db.ps1
Reads config.xml.

Creates the database if missing.

Uses InstanceName + DatabaseName from config.

powershell
# 02_create-db.ps1
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$instance = $config.config.InstanceName
$database = $config.config.DatabaseName
sqlcmd -S "(localdb)\$instance" -Q "IF DB_ID('$database') IS NULL CREATE DATABASE [$database];"
Write-Host "✅ Database '$database' ensured on instance '$instance'"
03_create-db-instance.ps1
Ensures LocalDB instance exists and starts it.

Uses config values for MDF/LDF placement. (You already have this — just keep consistent with config.xml.)

04_create-db-instance-tables.ps1
Reads <historytable> nodes from config.xml.

Creates/updates Lake_* tables with SessionCode, processed, and UNIQUE constraints.

powershell
# 04_create-db-instance-tables.ps1
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$cs = $config.config.ConnectionString
$tables = $config.config.historytable

$canonicalSchema = @"
CREATE TABLE dbo.{0} (
  Id INT IDENTITY(1,1) PRIMARY KEY,
  FileName NVARCHAR(260) NOT NULL,
  XmlContent XML NOT NULL,
  UploadTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  FileSize BIGINT NOT NULL,
  Sha256Hash CHAR(64) NOT NULL,
  OriginalCreationTime DATETIME2 NULL,
  OriginalLastWriteTime DATETIME2 NULL,
  SessionCode NVARCHAR(100) NULL,
  processed BIT NOT NULL DEFAULT 0,
  CONSTRAINT UQ_{0}_Hash UNIQUE (Sha256Hash),
  CONSTRAINT UQ_{0}_Session UNIQUE (SessionCode)
)
"@

$conn = New-Object System.Data.SqlClient.SqlConnection $cs
$conn.Open()
foreach ($t in $tables) {
  $tableName = "Lake_" + $t.name.Trim()
  $sql = [string]::Format($canonicalSchema, $tableName)
  $cmd = $conn.CreateCommand()
  $cmd.CommandText = $sql
  try { $cmd.ExecuteNonQuery(); Write-Host "✅ $tableName ensured" }
  catch { Write-Warning "⚠️ $tableName: $($_.Exception.Message)" }
}
$conn.Close()
05_upload-files.ps1
Reads config.xml.

Loops over <historytable> entries.

Uploads XMLs from HISTORY\<name> into Lake_<name>.

Dedupes by Sha256Hash and SessionCode.

06_run-etl.ps1
Reads config.xml.

Loops over all Lake_* tables.

Calls EXEC dbo.Etl_ProcessLakeTable @LakeTable=….

07_validate-etl.ps1
Runs EXEC dbo.Validate_ETL.

Dumps anomalies + recent ETL_ValidationLog.

✅ Why This Works
Convention‑aligned: Numbered scripts match your existing repo.

Config‑driven: No hardcoded table names; everything flows from config.xml.

Idempotent: Safe to re‑run; tables and DB are “ensured,” not blindly recreated.

Composable: Each script does one job; orchestrator can chain them.

👉 Next step: I can emit the full text of 05_upload-files.ps1, 06_run-etl.ps1, and 07_validate-etl.ps1 in this same style, so you’ve got the complete numbered bundle. Do you want me to go ahead and lay those out now?

yes
Excellent — let’s finish the bundle properly. Here are the remaining numbered scripts (05_upload-files.ps1, 06_run-etl.ps1, 07_validate-etl.ps1) rewritten to read from config.xml and follow the same naming convention as your existing proto‑repo. This way, the entire pipeline is config‑driven and consistent.

05_upload-files.ps1
Uploads XMLs from each history folder into its corresponding Lake_* table.

powershell
# 05_upload-files.ps1
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$instance = $config.config.InstanceName
$database = $config.config.DatabaseName
$tables   = $config.config.historytables.historytable

function Invoke-Sql([string]$Q){ & sqlcmd -S $instance -d $database -b -Q $Q }

foreach ($t in $tables) {
  $lake = "Lake_" + $t.name.Trim()
  $folder = Join-Path $PSScriptRoot "HISTORY\$($t.name)"
  Write-Host "=== Uploading from $folder into $lake ==="

  $files = Get-ChildItem -Path $folder -Filter *.xml -File -Recurse
  foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $sha = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    $hash = ([System.BitConverter]::ToString($sha)).Replace("-", "").ToLower()
    $xml = [xml](Get-Content -Path $f.FullName -Raw)
    $sessionCode = $xml.session.sessioncode
    if (-not $sessionCode) { $sessionCode = [System.IO.Path]::GetFileNameWithoutExtension($f.Name) }
    $xmlEsc = $xml.OuterXml.Replace("'", "''")

    try {
      Invoke-Sql @"
INSERT INTO dbo.$lake (FileName, XmlContent, UploadTime, FileSize, Sha256Hash, OriginalCreationTime, OriginalLastWriteTime, SessionCode, processed)
VALUES (N'$($f.Name)', CONVERT(XML, N'$xmlEsc'), SYSUTCDATETIME(), $($f.Length), '$hash',
        '$($f.CreationTimeUtc.ToString("o"))', '$($f.LastWriteTimeUtc.ToString("o"))', N'$sessionCode', 0);
"@
      Write-Host "  → Uploaded $($f.Name)"
    } catch {
      if ($_.Exception.Message -match "UQ_.*_Hash" -or $_.Exception.Message -match "UQ_.*_Session") {
        Write-Host "  → Skipped duplicate $($f.Name)"
      } else {
        Write-Warning "  → Error $($f.Name): $($_.Exception.Message)"
      }
    }
  }
}
06_run-etl.ps1
Runs the ETL procedure for each Lake_* table defined in config.

powershell
# 06_run-etl.ps1
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$instance = $config.config.InstanceName
$database = $config.config.DatabaseName
$lakes    = $config.config.historytables.historytable | ForEach-Object { "Lake_" + $_.name.Trim() }

function Sql([string]$q){ & sqlcmd -S $instance -d $database -b -Q $q }

$batchSize = 500
foreach ($lake in $lakes) {
  Write-Host "=== Processing $lake ==="
  Sql "EXEC dbo.Etl_ProcessLakeTable @LakeTable = N'$lake', @BatchSize = $batchSize;"
}
07_validate-etl.ps1
Runs validation and shows recent anomalies.

powershell
# 07_validate-etl.ps1
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$instance = $config.config.InstanceName
$database = $config.config.DatabaseName

function Sql([string]$q){ & sqlcmd -S $instance -d $database -b -Q $q }

$runId = [guid]::NewGuid().ToString()
Write-Host "=== Running ETL validation (RunId=$runId) ==="
Sql "EXEC dbo.Validate_ETL @RunId = '$runId';"

Write-Host "=== Recent anomalies ==="
Sql "SELECT TOP 20 * FROM dbo.ETL_ValidationLog ORDER BY log_time DESC;"
✅ Now You Have
01–04: Config, DB, instance, staging tables (already in your repo).

05: Upload files (config‑driven).

06: Run ETL (config‑driven).

07: Validate ETL (config‑driven).

This completes the convention‑aligned, config‑driven bundle. Drop these into your repo alongside the earlier scripts and you’ve got a clean, numbered pipeline from bootstrap to validation.

Would you like me to also refactor the master orchestrator into 08_master-orchestrator.ps1 that simply chains 02–07 in sequence, so you can run one script and get the full cycle?

yes
Here’s the final piece of your convention-aligned, config-driven pipeline: the master orchestrator script.

08_master-orchestrator.ps1
Chains scripts 02–07 in order, using config.xml as the single source of truth. This gives you a one-command ETL run: database creation, staging setup, upload, ETL, validation.

powershell
# 08_master-orchestrator.ps1
<#
Purpose: Full ETL pipeline run — from DB creation to validation.
Usage: .\08_master-orchestrator.ps1
#>

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
[xml]$config = Get-Content "$root\config.xml"

$instance = $config.config.InstanceName
$database = $config.config.DatabaseName
$tables   = $config.config.historytables.historytable | ForEach-Object { "Lake_" + $_.name.Trim() }

Write-Host "=== Poker ETL Orchestrator ==="
Write-Host "Instance: $instance"
Write-Host "Database: $database"
Write-Host "Lake tables: $($tables -join ', ')"

# Step 1: Create DB if missing
Write-Host "`n[Step 1] Ensuring database..."
& "$root\02_create-db.ps1"

# Step 2: Ensure Lake_* tables
Write-Host "`n[Step 2] Ensuring Lake_* staging tables..."
& "$root\04_create-db-instance-tables.ps1"

# Step 3: Upload XML files
Write-Host "`n[Step 3] Uploading XML files..."
& "$root\05_upload-files.ps1"

# Step 4: Run ETL
Write-Host "`n[Step 4] Running ETL shredders..."
& "$root\06_run-etl.ps1"

# Step 5: Validate
Write-Host "`n[Step 5] Validating ETL output..."
& "$root\07_validate-etl.ps1"

Write-Host "`n✅ ETL pipeline complete."
🧩 What You Now Have
Script	Purpose
01_create-config.ps1	Generate config.xml from folder layout
02_create-db.ps1	Create database if missing
03_create-db-instance.ps1	Ensure LocalDB instance
04_create-db-instance-tables.ps1	Create/update Lake_* tables
05_upload-files.ps1	Upload XMLs to Lake_*
06_run-etl.ps1	Shred Lake_* into relational schema
07_validate-etl.ps1	Run validation and show anomalies
08_master-orchestrator.ps1	Chain everything above
This is now a fully modular, config-driven, convention-aligned ETL pipeline. You can run each step manually or just call 08_master-orchestrator.ps1 to execute the full cycle.

If you want, I can also help you wrap this into a GitHub Actions or Azure DevOps pipeline for CI/CD — or generate a README that explains the whole flow for collaborators. Just say the word.