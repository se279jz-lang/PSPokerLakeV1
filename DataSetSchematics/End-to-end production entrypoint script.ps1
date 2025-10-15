<# 
    File: run-phh-pipeline.ps1
    Purpose: End-to-end entrypoint for Poker Hand History ETL
    Usage:  .\run-phh-pipeline.ps1 -Instance "(localdb)\MSSQLLocalDB" -Database "PHH" -HistoryRoot "D:\PHH\History" -Since "2025-10-01"
#>

param(
    [string]$Instance = "(localdb)\MSSQLLocalDB",
    [string]$Database = "PHH",
    [string]$HistoryRoot = "$env:USERPROFILE\PHH\History",
    [string]$Since = $null,                   # Optional ISO date (YYYY-MM-DD) to limit file scan
    [int]$BatchSize = 500                     # ETL batch size from Lake_* to relational
)

$ErrorActionPreference = "Stop"

function New-RunContext {
    $ctx = [ordered]@{
        StartTime   = Get-Date
        RunId       = [guid]::NewGuid().ToString()
        LogDir      = Join-Path -Path $PSScriptRoot -ChildPath "logs"
        LogPath     = $null
        ExitCode    = 0
        Metrics     = [ordered]@{
            FilesFound     = 0
            FilesUploaded  = 0
            FilesSkipped   = 0
            UploadErrors   = 0
            Sessions       = 0
            Players        = 0
            Hands          = 0
            Actions        = 0
            Results        = 0
            GlobalPlayers  = 0
            StagingPending = 0
        }
    }
    if (-not (Test-Path $ctx.LogDir)) { New-Item -ItemType Directory -Path $ctx.LogDir | Out-Null }
    $ctx.LogPath = Join-Path $ctx.LogDir ("run_{0}_{1}.log" -f ($ctx.RunId.Substring(0,8)), (Get-Date).ToString("yyyyMMdd_HHmmss"))
    return $ctx
}

function Write-Log([string]$msg, [string]$level = "INFO") {
    $line = "{0} [{1}] {2}" -f (Get-Date).ToString("o"), $level, $msg
    Write-Host $line
    Add-Content -Path $global:RunCtx.LogPath -Value $line
}

function Invoke-SqlScalar([string]$query) {
    $cmd = "sqlcmd -S `"$Instance`" -d `"$Database`" -W -h -1 -Q `"$query`""
    $out = Invoke-Expression $cmd
    return ($out | Select-Object -First 1)
}

function Invoke-SqlNonQuery([string]$query) {
    $cmd = "sqlcmd -S `"$Instance`" -d `"$Database`" -b -Q `"$query`""
    Invoke-Expression $cmd
}

function Run-Uploader {
    Write-Log "Starting uploader: HistoryRoot=$HistoryRoot Since=$Since"
    $uploader = Join-Path $PSScriptRoot "upload-files-to-db.ps1"
    if (-not (Test-Path $uploader)) { throw "Uploader script not found: $uploader" }

    # Pass through instance/db/root/since
    $args = @("-Instance `"$Instance`"", "-Database `"$Database`"", "-HistoryRoot `"$HistoryRoot`"")
    if ($Since) { $args += "-Since `"$Since`"" }

    & $uploader @args 2>&1 | ForEach-Object {
        $_ | Write-Log
        # Optional: parse summary lines if uploader writes them (e.g., "Uploaded: X, Skipped: Y")
        if ($_ -match "FilesFound:\s+(\d+)")     { $global:RunCtx.Metrics.FilesFound    = [int]$Matches[1] }
        if ($_ -match "FilesUploaded:\s+(\d+)")  { $global:RunCtx.Metrics.FilesUploaded = [int]$Matches[1] }
        if ($_ -match "FilesSkipped:\s+(\d+)")   { $global:RunCtx.Metrics.FilesSkipped  = [int]$Matches[1] }
        if ($_ -match "UploadErrors:\s+(\d+)")   { $global:RunCtx.Metrics.UploadErrors  = [int]$Matches[1] }
    }
    Write-Log "Uploader completed."
}

function Run-ETL {
    Write-Log "Starting ETL in batches of $BatchSize."

    # Example: process unprocessed rows in both Lake tables
    $lakeTables = @()
    $lakeTables += (Invoke-SqlScalar "SELECT name FROM sys.tables WHERE name LIKE 'Lake_%'")

    # If multiple Lake_* tables, get all
    $lakeTables = Invoke-SqlScalar "SET NOCOUNT ON; SELECT STRING_AGG(name, ',') FROM sys.tables WHERE name LIKE 'Lake_%'"
    $lakeTablesArray = $lakeTables -split ',' | Where-Object { $_ -and $_.Trim().Length -gt 0 }

    foreach ($lake in $lakeTablesArray) {
        $lake = $lake.Trim()
        Write-Log "Processing lake table: $lake"
        # Count pending
        $pending = Invoke-SqlScalar "SELECT COUNT(*) FROM [$lake] WHERE processed = 0"
        $global:RunCtx.Metrics.StagingPending += [int]$pending

        if ([int]$pending -gt 0) {
            # Call your stored procedure; adjust names to your implementation
            # Example proc: dbo.Etl_ProcessLakeTable @LakeTable, @BatchSize
            $proc = "EXEC dbo.Etl_ProcessLakeTable @LakeTable = N'$lake', @BatchSize = $BatchSize"
            Invoke-SqlNonQuery $proc
            Write-Log "ETL executed for $lake (batch size $BatchSize)."
        } else {
            Write-Log "No pending rows in $lake."
        }
    }
    Write-Log "ETL completed."
}

function Collect-Metrics {
    Write-Log "Collecting post-ETL metrics."

    $global:RunCtx.Metrics.Sessions      = [int](Invoke-SqlScalar "SELECT COUNT(*) FROM dbo.Sessions")
    $global:RunCtx.Metrics.Players       = [int](Invoke-SqlScalar "SELECT COUNT(*) FROM dbo.Players")
    $global:RunCtx.Metrics.Hands         = [int](Invoke-SqlScalar "SELECT COUNT(*) FROM dbo.Hands")
    $global:RunCtx.Metrics.Actions       = [int](Invoke-SqlScalar "SELECT COUNT(*) FROM dbo.Actions")
    $global:RunCtx.Metrics.Results       = [int](Invoke-SqlScalar "SELECT COUNT(*) FROM dbo.Results")
    $global:RunCtx.Metrics.GlobalPlayers = [int](Invoke-SqlScalar "SELECT COUNT(*) FROM dbo.PlayersGlobal")

    Write-Log ("Metrics summary: Sessions={0}, Players={1}, Hands={2}, Actions={3}, Results={4}, GlobalPlayers={5}, StagingPending={6}" -f `
        $global:RunCtx.Metrics.Sessions,
        $global:RunCtx.Metrics.Players,
        $global:RunCtx.Metrics.Hands,
        $global:RunCtx.Metrics.Actions,
        $global:RunCtx.Metrics.Results,
        $global:RunCtx.Metrics.GlobalPlayers,
        $global:RunCtx.Metrics.StagingPending
    )
}

# Main
$global:RunCtx = New-RunContext
Write-Log "Run started. Instance=$Instance Database=$Database HistoryRoot=$HistoryRoot RunId=$($global:RunCtx.RunId)"

try {
    Run-Uploader
    Run-ETL
    Collect-Metrics
    Write-Log "Pipeline completed successfully." "SUCCESS"
} catch {
    $global:RunCtx.ExitCode = 1
    Write-Log ("Pipeline failed: {0}" -f $_.Exception.Message) "ERROR"
} finally {
    $duration = (Get-Date) - $global:RunCtx.StartTime
    Write-Log ("Run finished in {0:mm\:ss} (hh:mm:ss total {1})" -f $duration, $duration.ToString()) "INFO"
    if ($global:RunCtx.ExitCode -ne 0) { exit $global:RunCtx.ExitCode }
}
<#
Orchestrator features
Inputs: instance, database, history root, and optional “since” date for incremental loads.
Ingestion: calls your uploader, enforces hash/session uniqueness.
ETL: runs stored procedures to shred XML into relational tables and maintain PlayersGlobal.
Metrics: summarizes counts and processed status.
Logging: timestamped run log file; per-step success/failure.
----------------
End-to-end production entrypoint script
Here’s a single PowerShell “biggie” you can run after a good night’s rest. 
It chains ingestion, ETL, and metrics into one reliable entrypoint with clear logs and exit codes.
#>