<p align="center"><img src="docs/logo.svg" width="160" alt="Minivakond logo: a red mole peeking out of the ground"></p>

# Minivakond

A Claude Code plugin that lets non-technical business users ask plain-language questions about their CSV and Excel files. It targets Hungarian users and runs on Windows only.

## What it does

- **Loads spreadsheets** into a local [DuckDB](https://duckdb.org/) database. It handles Hungarian CSV quirks: cp1250 encoding, `;` separators, decimal commas and `YYYY.MM.DD.` dates.
- **Clarifies the data** with the user: which column is the real measure, which rows count, which date to use. Each answer is saved as a numbered business rule and applied to every later answer.
- **Answers questions** with chat tables, HTML charts and reports (published as Artifacts), and Excel exports. Every number comes from a query that was actually run, and every answer lists the assumptions it made.

Example (in Hungarian, as the user would see it):

> **User:** Mennyi volt a forgalom júliusban régiónként?
>
> **Claude:** Júliusban a teljes nettó forgalom 124 000 000 Ft volt, ebből a Közép-Magyarország régió 41%-ot hozott. *(table)*
>
> **Feltételezések:** a sztornózott számlák nem számítanak bele (R-002).

## Install and use

1. Install the plugin from the marketplace:

   ```
   /plugin marketplace add vupdivup/minivakond
   ```

   ```
   /plugin install minivakond@minivakond
   ```

   Run `/plugin marketplace update minivakond` later to get new versions.
2. Open an empty folder in the **Code** tab and say *„állítsd be”* ("set it up"). Setup creates the workspace and downloads DuckDB.
3. Drop a spreadsheet into `inbox/` (or attach it) and start asking questions.

## How it works

```mermaid
flowchart TD
    start([Session starts]) --> ws[workspace: load conventions]
    ws --> check{duckdb.exe missing or<br>workspace version outdated?}
    check -- yes --> setup[setup: create or repair workspace]
    check -- no --> build
    setup --> build[Rebuild database from data/build.sql]
    build --> greet[Status greeting + suggested questions]

    greet --> file([User adds a file])
    greet --> question([User asks a question])

    file --> ingest[ingest: raw_name table + v_name view]
    ingest -- open issues --> clarify[clarify: ask the user, record rules]
    question --> report[report: query v_* views]
    report -- ambiguous term --> clarify
    clarify -- rules in business_rules.md + views.sql --> report

    report --> chat[Chat table]
    report --> page[report.json → build_report.ps1 → HTML Artifact]
    report --> xlsx[Excel export]
```

1. **Session start.** The `workspace` skill loads first in every session. If `tools/duckdb.exe` is missing or the workspace's version marker differs from the plugin version, it runs `setup`. It then rebuilds the database and greets the user with the loaded datasets, rule count, open questions, recent answers and new files in `inbox/`.
2. **New file.** `ingest` copies the file into `data/raw/` (never modified afterwards), loads it into a `raw_<name>` table and creates a `v_<name>` view. It records the original column headers and hands open questions to `clarify`.
3. **Ambiguity.** `clarify` looks for problems in the data itself, asks the user with concrete choices, and records each answer twice: as a human-readable rule (`R-001`, …) in `rules/business_rules.md`, and as SQL in `rules/views.sql`.
4. **Question.** `report` queries only the `v_*` views, so every answer applies the agreed rules. It picks the lightest output that fits: a chat table, a chart page, a full report page or an Excel file. It logs every answer in `reports/log.md`.

## Architecture

### Repository layout

```
plugin/                          everything that ships
  .claude-plugin/plugin.json     manifest; "version" drives workspace upgrades
  skills/
    workspace/                   conventions, session-start routine, golden rules
    setup/
      setup.ps1                  creates or repairs a workspace
      assets/                    workspace template copied into the user's folder
    ingest/                      file loading
    clarify/                     business rules
    report/
      spec.md                    report.json format
.claude-plugin/marketplace.json  marketplace entry, so the repo installs with /plugin marketplace add
.github/workflows/release.yml    publishes a GitHub Release with notes on a v* tag
.claude/skills/                  dev-only skills for this repo (create-issue, open-pr, release)
```

### Skills

| Skill | Role | Triggers |
|---|---|---|
| `workspace` | Conventions, session-start routine, golden rules. Every other skill loads it first. | Any session in a folder with `.claude/minivakond-version` |
| `setup` | Creates or repairs a workspace: folders, starter files, helper scripts, DuckDB. Safe to re-run. | First run, missing tools, outdated version, "nem működik" |
| `ingest` | Loads a CSV or Excel file into a `raw_<name>` table and a `v_<name>` view. | New file in `inbox/`, attached or mentioned |
| `clarify` | Finds ambiguities in the data and records the answers as business rules. | Ambiguity that changes an answer, "nézzük át a szabályokat" |
| `report` | Answers questions with tables, charts, reports and Excel exports. | Any question about the data |

### Workspace

A workspace is the user's folder, marked by `.claude/minivakond-version`. Setup creates this layout:

```
CLAUDE.md                   pointer to the workspace skill
.claude/settings.json       permissions (data/raw/ is write-protected)
.claude/minivakond-version  workspace marker + plugin version
inbox/                      user drops new files here
data/raw/                   original files (read-only)
data/load.sql               loads each raw file into a raw_* table
data/build.sql              rebuilds everything: load.sql, then rules/views.sql
data/work.duckdb            the database; disposable, rebuilt every session
rules/business_rules.md     rules, glossary, data facts, open questions
rules/views.sql             the same rules as v_* views
reports/log.md              one line per answered question
reports/<date>_<slug>/      SQL files, notes.md, report.json + report.html / .xlsx
tools/                      duckdb.exe, helper scripts, report template
```

**File ownership.** User-owned starter files (`data/`, `rules/`, `reports/`, `CLAUDE.md`) are created only when missing and never overwritten. Plugin-owned files (everything from `assets/tools/`, `.claude/settings.json` and the version marker) are always refreshed.

**Upgrades.** When the marker differs from `version` in `plugin.json`, the next session re-runs setup. Bump the version whenever `assets/` or `tools/` change.

### Helper scripts

All live in `plugin/skills/setup/assets/tools/` and are copied into the workspace's `tools/`.

| Script | Purpose |
|---|---|
| `install_duckdb.ps1` | Downloads the latest DuckDB CLI into `tools/duckdb.exe`. |
| `copy_raw.ps1` | Copies a source file into `data/raw/`, which the Edit and Write tools can't touch. |
| `list_sheets.ps1` | Lists the sheet names of an `.xlsx` file (DuckDB can't). |
| `build_report.ps1` | Runs the SQL files named in `report.json` and renders `report.html` from `report_template.html`. No number is typed by hand. |
| `export_pdf.ps1` | Prints `report.html` to an A4 `report.pdf` with headless Edge, so CSS page breaks apply. The desktop app's own export rasterises the page and ignores them (#37). |

### Golden rules

- Every reported number comes from a query that was actually run.
- Files in `data/raw/` are never modified.
- Answers query `v_*` views only, never `raw_*` tables.
- Every user decision is recorded as a rule before it is used.
- Published pages contain only aggregated data, never row-level or personal data.

## Development

- **Validate:** `claude plugin validate .` checks the marketplace manifest; `claude plugin validate plugin` checks the plugin.
- **Test:** there are no automated tests. Open an empty folder and run `claude --plugin-dir <repo>\plugin` to load the plugin from the working tree.
- **Release:** the `release` skill bumps `plugin.json` through a PR. Merging it ships the version to marketplace users. The skill then tags `main`, which triggers `release.yml` to publish a GitHub Release with generated notes. A version with a suffix (e.g. `0.2.0-rc.1`) is published as a prerelease.
- **Conventions:**
  - Conventional commits (`feat:`, `fix:`, `docs:`…) on feature branches.
  - Files are UTF-8 without BOM.
  - User-facing text is Hungarian; internal names are ASCII English snake_case.
- `CLAUDE.md` in the repo root is for developing this repo. The `CLAUDE.md.tmpl` in `assets/` is what goes into user workspaces.
