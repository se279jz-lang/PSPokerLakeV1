# fix-sql-duplicates.ps1
# Moves duplicate SQL files into canonical numbered files and archives extras into snippets/experimental/templates
param(
    [switch]$Perform
)

$repoRoot = Resolve-Path -Path .
Set-Location $repoRoot
$sqlDir = Join-Path $repoRoot 'DataSetSchematics\sql'
if (-not (Test-Path $sqlDir)) { Write-Error "SQL directory not found: $sqlDir"; exit 1 }

$moves = @(
    @{From='core-shared-schema.sql'; To='01_core-schema.sql'; Archive='snippets/core-shared-schema.sql'},
    @{From='PlayersGlobal.sql'; To='02_players-global.sql'; Archive='snippets/PlayersGlobal.sql'},
    @{From='tournament-extensions.sql'; To='03_tournament-extensions.sql'; Archive='snippets/tournament-extensions.sql'},
    @{From='cash-game-extensions.sql'; To='04_cash-extensions.sql'; Archive='snippets/cash-game-extensions.sql'},
    @{From='ETL_ValidationLog .sql'; To='05_etl-validationlog.sql'; Archive='snippets/ETL_ValidationLog.sql'},
    @{From='Etl_ProcessLakeTable.sql'; To='06_etl-process-laketable.sql'; Archive='snippets/Etl_ProcessLakeTable.sql'},
    @{From='Validate_ETL_II.sql'; To='07_validate-etl.sql'; Archive='snippets/Validate_ETL_II.sql'},
    @{From='ControlPanel.sql'; To='08_controlpanel.sql'; Archive='snippets/ControlPanel.sql'},
    @{From='extended-sessions-table.sql'; To='09_extended-sessions.sql'; Archive='snippets/extended-sessions-table.sql'},
    @{From='ingest-session.headline.sql'; To='snippets/ingest-session.headline.orig.sql'; Archive=$null},
    @{From='sproc-etl-shredder.sql'; To='experimental/sproc-etl-shredder.sql'; Archive=$null},
    @{From='Staging Table Template.sql'; To='templates/StagingTableTemplate.sql'; Archive=$null}
)

# Ensure archive dirs
$dirs = @('snippets','experimental','templates') | ForEach-Object { Join-Path $sqlDir $_ }
foreach ($d in $dirs) { if (-not (Test-Path $d)) { Write-Host "Creating directory: $d"; if ($Perform) { New-Item -ItemType Directory -Path $d | Out-Null } } }

$useGit = Test-Path (Join-Path $repoRoot '.git')

foreach ($m in $moves) {
    $src = Join-Path $sqlDir $m.From
    if (-not (Test-Path $src)) { Write-Host "Source not found, skipping: $($m.From)"; continue }

    $canonical = Join-Path $sqlDir $m.To
    # If canonical target exists and is same content, remove source to avoid duplication; else if canonical missing, move source to canonical

    if (Test-Path $canonical) {
        # compare content
        $same = $false
        try { $same = (Get-Content -Path $src -Raw) -eq (Get-Content -Path $canonical -Raw) } catch {}
        if ($same) {
            Write-Host "Canonical exists and identical: $($m.To). Removing duplicate: $($m.From)"
            if ($Perform) { Remove-Item -Path $src -Force }
            continue
        } else {
            # move to archive location instead
            if ($m.Archive) {
                $archivePath = Join-Path $sqlDir $m.Archive
                $archiveDir = Split-Path $archivePath -Parent
                if (-not (Test-Path $archiveDir)) { if ($Perform) { New-Item -ItemType Directory -Path $archiveDir | Out-Null } }
                Write-Host "Canonical exists but different. Archiving $($m.From) -> $($m.Archive)"
                if ($Perform) {
                    if ($useGit) { git mv -- "$src" "$archivePath" } else { Move-Item -Path $src -Destination $archivePath -Force }
                }
                continue
            } else {
                Write-Host "Canonical exists and no archive specified. Leaving: $($m.From)"
                continue
            }
        }
    } else {
        # canonical missing, move/rename source to canonical
        Write-Host "Renaming $($m.From) -> $($m.To)"
        if ($Perform) {
            try {
                if ($useGit) { git mv -- "$src" "$canonical" } else { Move-Item -Path $src -Destination $canonical -Force }
            } catch {
                Write-Warning "Move failed, attempting copy+delete: $_"
                Copy-Item -Path $src -Destination $canonical -Force
                Remove-Item -Path $src -Force
            }
        }
    }
}

# After moves, commit if git and Perform
if ($Perform -and $useGit) {
    try { git add DataSetSchematics/sql; git commit -m "chore(sql): canonicalize migrations and archive duplicates"; Write-Host 'Committed changes' } catch { Write-Warning 'Git commit failed or nothing to commit' }
}

Write-Host "Finished. Run with -Perform to apply changes."