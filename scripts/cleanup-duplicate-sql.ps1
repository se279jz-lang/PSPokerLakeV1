# cleanup-duplicate-sql.ps1
# Move duplicate SQL artifacts into snippets/templates/experimental folders
param(
    [switch]$Perform
)

$root = Resolve-Path -Path "PSPokerLakeV1\DataSetSchematics\sql"
$srcDir = $root.Path
Write-Host "Scanning: $srcDir"

$mappings = @{
    'core-shared-schema.sql' = 'snippets/core-shared-schema.sql'
    'PlayersGlobal.sql' = 'snippets/PlayersGlobal.sql'
    'tournament-extensions.sql' = 'snippets/tournament-extensions.sql'
    'cash-game-extensions.sql' = 'snippets/cash-game-extensions.sql'
    'ETL_ValidationLog .sql' = 'snippets/ETL_ValidationLog.sql'
    'Etl_ProcessLakeTable.sql' = 'snippets/Etl_ProcessLakeTable.sql'
    'Validate_ETL_II.sql' = 'snippets/Validate_ETL_II.sql'
    'ControlPanel.sql' = 'snippets/ControlPanel.sql'
    'extended-sessions-table.sql' = 'snippets/extended-sessions-table.sql'
    'ingest-session.headline.sql' = 'snippets/ingest-session.headline.orig.sql'
    'sproc-etl-shredder.sql' = 'experimental/sproc-etl-shredder.sql'
    'Staging Table Template.sql' = 'templates/StagingTableTemplate.sql'
}

# ensure dirs
$dirs = @('snippets','experimental','templates') | ForEach-Object { Join-Path $srcDir $_ }
foreach ($d in $dirs) { if (-not (Test-Path $d)) { Write-Host "Creating dir: $d"; if ($Perform) { New-Item -ItemType Directory -Path $d | Out-Null } } }

$useGit = Test-Path (Join-Path $root.Path '.git') -PathType Any -ErrorAction SilentlyContinue
if (-not $useGit) { # detect git by repo root
    $gitTest = (Get-ChildItem -Path $root.Path -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName '.git') })
    if ($gitTest) { $useGit = $true }
}

foreach ($kv in $mappings.GetEnumerator()) {
    $fromName = $kv.Key
    $toRel = $kv.Value
    $fromPath = Join-Path $srcDir $fromName
    if (-not (Test-Path $fromPath)) {
        Write-Host "Not present: $fromName"
        continue
    }
    $toPath = Join-Path $srcDir $toRel
    $toDir = Split-Path $toPath -Parent
    if (-not (Test-Path $toDir)) { Write-Host "Create dir $toDir"; if ($Perform) { New-Item -ItemType Directory -Path $toDir | Out-Null } }

    Write-Host "Preparing move: $fromName -> $toRel"
    if (-not $Perform) { continue }

    try {
        if ($useGit) {
            git mv -- "$fromPath" "$toPath"
            Write-Host "git mv performed"
        } else {
            Move-Item -Path $fromPath -Destination $toPath -Force
            Write-Host "Moved file"
        }
    } catch {
        Write-Warning ("Move failed: {0} - attempting file copy and delete" -f $_.Exception.Message)
        try {
            Copy-Item -Path $fromPath -Destination $toPath -Force
            Remove-Item -Path $fromPath -Force
            Write-Host "Copied and removed source"
        } catch {
            Write-Error ("Failed to move/copy {0}: {1}" -f $fromName, $_.Exception.Message)
        }
    }
}

if ($Perform -and $useGit) {
    try { git add DataSetSchematics/sql; git commit -m "chore(sql): move duplicates to snippets/templates/experimental"; Write-Host 'Committed' } catch { Write-Warning 'Git commit failed or nothing to commit' }
}

Write-Host 'Done (dry-run=false means performed).'
