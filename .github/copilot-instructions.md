Here’s the **lossless fit (full but compact summary)** of your `copilot-instructions.md` page — nothing dropped, just reorganised into a clean outline so you can see every element without duplication:

---

## 📄 Lossless Fit Summary of `copilot-instructions.md`

### Purpose
- Document project conventions so **Copilot and contributors** follow a consistent, discoverable style.
- Applies to Poker Hand History ETL (iPoker, Betfair, etc.).

---

### High‑Level Principles
- **Config‑driven**: All environment values (instance, database, history) come from `config.xml`.  
- **Numbered scripts**: Prefix (`01_…`, `02_…`) indicates order and intent.  
- **Idempotent**: Use `IF NOT EXISTS`, `CREATE OR ALTER`, or checks in PowerShell.  
- **Small focus**: Scripts are composable; orchestration handled by orchestrators (`08_master-orchestrator.ps1`).  
- **Minimalist, ergonomic style**: clarity and convention over verbosity.  

---

### PowerShell Conventions
- Load config once at top:  
  ```powershell
  [xml]$config = Get-Content "$PSScriptRoot\config.xml"
  ```
  Use `.ToString().Trim()` when referencing fields.  
- Accept `-ConfigPath` and `-HistoryRoot` overrides.  
- Use `sqlcmd` for quick ops, ADO.NET for multi‑statement.  
- Deduplicate uploads by `Sha256Hash` and `SessionCode`.  
- Logging: `Write-Host` for status, `Write-Warning` for recoverable issues.  
- Orchestrators set `$ErrorActionPreference = 'Stop'`.  

---

### SQL / Migration Conventions
- SQL artifacts live in `/sql` or `DataSetSchematics/migrations/`, numbered sequentially (`001_description.sql`).  
- Each migration = one logical change.  
- Use `CREATE OR ALTER` for procs; wrap DDL in checks if needed.  
- Staging tables named `Lake_*` with:  
  - `processed BIT NOT NULL DEFAULT 0`  
  - `SessionCode` column  
  - `UNIQUE` constraints on `Sha256Hash` and `SessionCode`  
- Core schema: `Sessions`, `Players`, `Hands`, `Actions`, `Results`, `PlayersGlobal`.  
- ETL procedure: `Etl_ProcessLakeTable(@LakeTable, @BatchSize)`.  
- Validation procedure: `Validate_ETL(@RunId)` logs to `ETL_ValidationLog`.  
- Control panel query: `ControlPanel.sql`.  

---

### Repository Layout
- `DataSetSchematics/` → SQL, wireframes, canonical scripts.  
- `clean bundle/` → curated bootstrap scripts.  
- `/scripts` → numbered PowerShell orchestrators.  
- `/sql` or `/migrations` → SQL schema and migrations.  
- `/docs` → architecture notes.  
- `config.xml` → single source of truth.  

---

### Commit & PR Guidance
- Each migration in its own commit: `migrations: NNN description`.  
- Refactors isolated from behavioral changes.  
- Prefer small PRs; include local run instructions.  

---

### Copilot Behaviour
- Suggest next available migration number.  
- Use `CREATE OR ALTER` and header comments with purpose/date.  
- Keep config field names consistent (`InstanceName`, `DatabaseName`, `HistoryDirectory`, `ConnectionString`).  
- Avoid reproducing scripts verbatim; prefer ergonomic variations.  

---

### Examples
- Migration file: `003_add_players_balance_column.sql`.  
- Script header:  
  ```powershell
  # 05_upload-files.ps1 — uploads History/* into Lake_* tables (config-driven)
  ```

---

### Extensions
- New scripts continue numbering (`09_feature-views.sql`, `10_ml-experiments.ps1`).  
- ML feature views expose poker metrics (VPIP, PFR, aggression factor, etc.) as SQL views.  
- Always config‑driven and convention‑aligned.  

---

✅ That’s the **lossless fit**: every element from both instruction blocks is preserved, but merged into one clean outline.  

Would you like me to now **format this into a ready‑to‑commit replacement file** (so you can drop it straight into `.github/copilot-instructions.md`)?