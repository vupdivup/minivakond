# Minivakond

Claude Code plugin that lets non-technical (mostly Hungarian) business users query their CSV/Excel files in plain language. Claude loads files into DuckDB, records business rules with the user, and answers with tables, HTML charts/reports and Excel exports. Windows-only (PowerShell + `duckdb.exe`).

## Layout

- `plugin/` — the plugin itself; everything here ships.
  - `.claude-plugin/plugin.json` — manifest. `version` is the source of truth for workspace upgrades.
  - `skills/workspace/` — conventions + session-start routine. Every other skill loads it first.
  - `skills/setup/` — creates/repairs a workspace. `setup.ps1` copies `assets/` into the user's folder.
    - `assets/` — workspace template: starter SQL (`data/`, `rules/`), `reports/log.md`, `CLAUDE.md.tmpl`, `.claude/settings.json`, `tools/` (helper scripts, `build_report.ps1` + `report_template.html`).
  - `skills/ingest/` — loads a file into `raw_<name>` table + `v_<name>` view; handles Hungarian CSV quirks (cp1250, `;`, decimal comma, `YYYY.MM.DD.`).
  - `skills/clarify/` — finds data ambiguities, records answers in `rules/business_rules.md` / `rules/views.sql`.
  - `skills/report/` — answers questions; `spec.md` documents the `report.json` format that `tools/build_report.ps1` turns into a chart/report page.
- `docs/` — not shipped.
  - `index.html` — getting-started landing page.
  - `logo.svg` — project logo, used in `README.md`.
- `.claude-plugin/marketplace.json` — makes this repo a plugin marketplace (`/plugin marketplace add vupdivup/minivakond`). Points at `./plugin`; installs track `main`, so keep `main` releasable.

## Key concepts

- **Workspace** = a user folder marked by `.claude/minivakond-version`. Not this repo.
- **Two instruction files**: this `AGENTS.md` (dev) vs. `plugin/skills/setup/assets/CLAUDE.md.tmpl` (installed into user workspaces as `CLAUDE.md`). Don't mix them up.
- **File ownership in a workspace**: user-owned starters (including `.claude/settings.json`) are created only if missing; plugin-owned files (files from `assets/tools/`, version marker) are always overwritten. Keep this split when adding assets.
- **Permissions**: users are expected to run in auto mode, so the workspace `settings.json` has no allow list, only a deny rule that keeps `data/raw/` read-only for Edit/Write. Changes to it don't reach existing workspaces.
- **Versioning**: merging to `main` ships to users, but `/plugin marketplace update` only picks up a new `plugin.json` `version`. Bump it in every PR that changes `plugin/`. Before bumping, rebase onto the latest `main` so the bump starts from the current version and doesn't collide with another PR's. Workspaces also re-run setup when their marker differs from this version.
- **DuckDB**: not expected on PATH. `setup.ps1` runs `tools/install_duckdb.ps1` when `tools/duckdb.exe` is missing; it downloads a pinned Windows CLI release (`$version` in that script) from GitHub into the workspace's `tools/`. To upgrade, check the release's asset names first; v2.0.0 renamed them. Skills always call it as `./tools/duckdb.exe`.
- **PowerShell**: helper scripts run under stock Windows PowerShell 5.1 (`powershell`, not `pwsh`), so avoid 7+ syntax (`&&`, `??`, ternary). Skills invoke them as `powershell -NoProfile -ExecutionPolicy Bypass -File tools/<script>.ps1`.
- User-facing text is Hungarian (chat may follow the user's language, files and reports may not); internal names (tables, columns, folders) are ASCII English snake_case.
- Files are UTF-8 without BOM (Hungarian accents). PowerShell's `Get-Content` may display them garbled; that's a display issue, not file corruption.

## Working principles

- **Design for model autonomy**: prefer simple skills and tools that give the model clear goals and conventions and leave the details to its judgment. Don't script every step or add guardrails for edge cases a modern frontier model handles on its own. Add structure (helper scripts, fixed formats, explicit checks) only where it's needed for reliable outputs.
- **Dev-supplied data is sensitive**: treat any sample data, CSV/Excel files or workspace contents the developer provides as potentially confidential. Never commit, push or upload them anywhere (git, issues, PRs, gists, external services). Test fixtures that go into the repo must be synthetic.

## Documentation

- When a change affects anything `README.md`, `docs/index.html` or this file describes (layout, skills, tools, install steps, conventions), update them in the same PR. `docs/index.html` is the main user guide; `README.md` only links to it for getting started.
- When adding something the user dictated to this file or other docs, reword it if the original phrasing would be ambiguous or hard to parse later.
