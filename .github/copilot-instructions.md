House style conventions for Poker Hand History ETL (for Copilot and contributors)

Purpose
- This file documents the project conventions so automated agents (and humans) follow a consistent, discoverable style.

High-level principles
- Config-driven: All environment-specific values (instance names, database names, history folders) must come from `config.xml` in the same folder as the scripts.
- Numbered scripts: Shell/PowerShell scripts in the `DataSetSchematics` area follow a numeric prefix (01_, 02_, ...) to indicate order and intent. Each file does a single job.
- Idempotent operations: Scripts should `ensure` resources rather than blindly recreate them (use `IF NOT EXISTS`, `CREATE OR ALTER`, or checks in PowerShell). This enables safe repeated runs.
- Small focus: Scripts should be composable; orchestration is done by an orchestrator (e.g., `08_master-orchestrator.ps1`).

PowerShell conventions
- Load config once at the top with `[xml]$config = Get-Content "$PSScriptRoot\config.xml"` and `.ToString().Trim()` when using individual fields.
- Prefer parameterized scripts that accept `-ConfigPath` and `-HistoryRoot` when appropriate; parameters override `config.xml` values.
- Use `sqlcmd` for quick operations when appropriate, but prefer parameterized ADO.NET for multi-statement or programmatic interactions.
- Use `Write-Host` for status and `Write-Warning` for recoverable problems. Set `$ErrorActionPreference = 'Stop'` in orchestrators.

SQL/migration conventions
- SQL artifacts (schema, stored procs, migrations) live in `DataSetSchematics/migrations/` and are numbered sequentially (e.g., `001_...sql`, `002_...sql`).
- Use `CREATE OR ALTER` for stored procedures and idempotent constructs where supported, or wrap DDL in checks for objects when necessary.
- Each migration file should do one logical change and be named `NNN_description.sql` where `NNN` is a zero-padded sequence number.

Repository layout guidance
- `DataSetSchematics/` contains SQL, wireframes, and the canonical scripts. The `clean bundle` folder contains curated scripts for bootstrap runs.
- `config.xml` is the single source of truth for instance/database/history; other scripts should reference it.

Commit messaging & PR guidance
- Each migration change should be introduced in its own commit with message: `migrations: NNN description`.
- Script refactors should be isolated from behavioral changes. Prefer small PRs and include how to run locally in the PR description.

How Copilot should behave
- When suggesting new migrations, propose the next available zero-padded number in `DataSetSchematics/migrations/`.
- When authoring SQL, prefer `CREATE OR ALTER` for procs and include brief header comments stating purpose and authoring date.
- When modifying scripts that read `config.xml`, keep the same field names (InstanceName, DatabaseName, HistoryDirectory, ConnectionString) and apply `.ToString().Trim()` before use.

Examples
- New migration file: `DataSetSchematics/migrations/003_add_players_balance_column.sql`
- Script header: `# 05_upload-files.ps1 — uploads History/* into Lake_* tables (config-driven)`

- # GitHub Copilot Instructions

This repository implements a config‑driven ETL pipeline for ingesting and analyzing poker hand histories (iPoker, Betfair, etc.). Copilot should follow these conventions when generating code or completions:

## General Conventions
- Scripts are **numbered** (`01_…` through `08_…`) and modular. Each script does one job.
- **Config‑driven**: All scripts read from `config.xml` for instance, database, and history table definitions. No hardcoded paths.
- **Idempotent**: Scripts should create‑if‑missing and be safe to re‑run.
- **Minimalist, ergonomic style**: prefer clarity and convention over verbosity.

## PowerShell
- Use PowerShell for orchestration (`02_create-db.ps1`, `05_upload-files.ps1`, etc.).
- Always read `config.xml` at the top of the script.
- Use `sqlcmd` or `Invoke‑Sqlcmd` for database calls.
- Deduplicate uploads by `Sha256Hash` and `SessionCode`.
- Include clear `Write-Host` logging for each major step.

## SQL
- Staging tables are named `Lake_*` with:
  - `processed BIT NOT NULL DEFAULT 0`
  - `SessionCode` column
  - `UNIQUE` constraints on `Sha256Hash` and `SessionCode`
- Core schema includes `Sessions`, `Players`, `Hands`, `Actions`, `Results`, `PlayersGlobal`.
- ETL procedure: `Etl_ProcessLakeTable(@LakeTable, @BatchSize)`.
- Validation procedure: `Validate_ETL(@RunId)` logs to `ETL_ValidationLog`.
- Control panel query: `ControlPanel.sql` shows throughput, backlog, anomalies.

## Deployment
- SQL scripts live in `sql/` or `migrations/` and should be numbered.
- PowerShell scripts live in `scripts/` and follow the numbered convention.
- CI/CD should lint PowerShell, apply SQL migrations, and run validation.

## Extensions
- New scripts should continue numbering (`09_feature-views.sql`, `10_ml-experiments.ps1`, etc.).
- ML feature views should expose standard poker metrics (VPIP, PFR, aggression factor, etc.) as SQL views.
- Always prefer config‑driven, convention‑aligned solutions.


This document is intentionally short. Keep changes to conventions explicit and propose new conventions via small PRs that update this file.