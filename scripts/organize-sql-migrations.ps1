param(
  [switch]$DryRun
)

$root = Resolve-Path -Path "."
Write-Host "Repository root: $root"

$moves = @(
  @{ From='DataSetSchematics/sql/core-shared-schema.sql'; To='DataSetSchematics/sql/01_core-schema.sql' },
  @{ From='DataSetSchematics/sql/PlayersGlobal.sql'; To='DataSetSchematics/sql/02_players-global.sql' },
  @{ From='DataSetSchematics/sql/tournament-extensions.sql'; To='DataSetSchematics/sql/03_tournament-extensions.sql' },
  @{ From='DataSetSchematics/sql/cash-game-extensions.sql'; To='DataSetSchematics/sql/04_cash-extensions.sql' },
  @{ From='DataSetSchematics/sql/ETL_ValidationLog .sql'; To='DataSetSchematics/sql/05_etl-validationlog.sql' }, # note stray space
  @{ From='DataSetSchematics/sql/Etl_ProcessLakeTable.sql'; To='DataSetSchematics/sql/06_etl-process-laketable.sql' },
  @{ From='DataSetSchematics/sql/Validate_ETL_II.sql'; To='DataSetSchematics/sql/07_validate-etl.sql' },
  @{ From='DataSetSchematics/sql/ControlPanel.sql'; To='DataSetSchematics/sql/08_controlpanel.sql' },
  @{ From='DataSetSchematics/sql/extended-sessions-table.sql'; To='DataSetSchematics/sql/09_extended-sessions.sql' },
  @{ From='DataSetSchematics/sql/ingest-session.headline.sql'; To='DataSetSchematics/sql/snippets/ingest-session.headline.sql' },
  @{ From='DataSetSchematics/sql/sproc-etl-shredder.sql'; To='DataSetSchematics/sql/experimental/sproc-etl-shredder.sql' },
  @{ From='DataSetSchematics/sql/Staging Table Template.sql'; To='DataSetSchematics/sql/templates/StagingTableTemplate.sql' }
)

# Create required dirs
$dirs = @('DataSetSchematics/sql/snippets','DataSetSchematics/sql/experimental','DataSetSchematics/sql/templates')
foreach ($d in $dirs) {
  if (-not (Test-Path $d)) {
    Write-Host "Creating: $d"
    if (-not $DryRun) { New-Item -ItemType Directory -Path $d | Out-Null }
  }
}

# Perform moves using git mv if repo detected, else Move-Item
$useGit = (Test-Path ".git")
foreach ($m in $moves) {
  $from = $m.From
  $to = $m.To
  if (-not (Test-Path $from)) {
    Write-Host "Skip (not found): $from"
    continue
  }
  Write-Host "Moving: $from -> $to"
  if ($DryRun) { continue }
  $toDir = Split-Path $to -Parent
  if (-not (Test-Path $toDir)) { New-Item -ItemType Directory -Path $toDir | Out-Null }
  if ($useGit) {
    git mv -- "$from" "$to"
  } else {
    Move-Item -Path $from -Destination $to -Force
  }
}

if (-not $DryRun -and $useGit) {
  git add DataSetSchematics/sql
  git commit -m "migrations: canonicalize SQL into numbered /sql sequence and move snippets/experimental/templates"
  Write-Host "Committed changes to git."
} else {
  Write-Host "Dry run or no git: changes not committed."
}
