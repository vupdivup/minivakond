# Minivakond

Claude Code plugin that lets non-technical (mostly Hungarian) business users query their CSV/Excel files in plain language. Claude loads files into DuckDB, records business rules with the user, and answers with tables, HTML charts/reports and Excel exports. Windows-only (PowerShell + `duckdb.exe`).

## Layout

- `plugin/` — the plugin itself; everything here ships.
  - `.claude-plugin/plugin.json` — manifest. `version` is the source of truth for workspace upgrades.
  - `skills/workspace/` — conventions + session-start routine. Every other skill loads it first.
  - `skills/setup/` — creates/repairs a workspace. `setup.ps1` copies `assets/` into the user's folder.
    - `assets/` — workspace template: starter SQL (`data/`, `rules/`), `CLAUDE.md.tmpl`, `.claude/settings.json`, `tools/` (helper scripts, `build_report.ps1` + `report_template.html`).
  - `skills/ingest/` — loads a file into `raw_<name>` table + `v_<name>` view; handles Hungarian CSV quirks (cp1250, `;`, decimal comma, `YYYY.MM.DD.`).
  - `skills/clarify/` — finds data ambiguities, records answers in `rules/business_rules.md` / `rules/views.sql`.
  - `skills/report/` — answers questions; `spec.md` documents the `report.json` format that `tools/build_report.ps1` turns into a chart/report page.
- `docs/logo.svg` — project logo, used in `README.md`. Not shipped.
- `.claude-plugin/marketplace.json` — makes this repo a plugin marketplace (`/plugin marketplace add vupdivup/minivakond`). Points at `./plugin`; installs track `main`, so keep `main` releasable.

## Key concepts

- **Workspace** = a user folder marked by `.claude/minivakond-version`. Not this repo.
- **Two CLAUDE.md files**: this one (dev) vs. `plugin/skills/setup/assets/CLAUDE.md.tmpl` (installed into user workspaces). Don't mix them up.
- **File ownership in a workspace**: user-owned starters are created only if missing; plugin-owned files (files from `assets/tools/`, `.claude/settings.json`, version marker) are always overwritten. Keep this split when adding assets.
- **Upgrades**: workspaces re-run setup when their marker differs from `plugin.json` `version`, so bump the version when assets or `tools/` change.
- User-facing text is Hungarian (chat may follow the user's language, files and reports may not); internal names (tables, columns, folders) are ASCII English snake_case.
- Files are UTF-8 without BOM (Hungarian accents). PowerShell's `Get-Content` may display them garbled; that's a display issue, not file corruption.

## Commands

- Validate manifests: `claude plugin validate .` (marketplace) and `claude plugin validate plugin` (plugin).
- No tests. To try a change, open an empty folder and run `claude --plugin-dir <repo>\plugin`. This loads the plugin straight from the working tree for that session; restart `claude` after each edit. Setup only re-runs when the version changes, so to retest it in a used folder, delete `.claude/minivakond-version` first.

## Communication

- Use the `caveman` skill by default.

## Git

- Never commit unless the user asks.
- Use conventional commits (`feat:`, `fix:`, `docs:`…).
- Work on feature branches, not `main`.

## Documentation

- When adding something the user dictated to this file or other docs, reword it if the original phrasing would be ambiguous or hard to parse later.
