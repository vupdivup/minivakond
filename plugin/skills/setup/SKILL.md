---
name: setup
description: Creates a new "Minivakond" workspace in the current folder, or repairs/updates an existing one (query engine, folders, starter files). Use on first run in a new folder, when tools/duckdb.exe is missing, when the workspace version is outdated, or when the user says something is broken or not working ("állítsd be", "új projekt", "nem működik", "hibát ír", "valami elromlott").
---

# Setup / doctor

Setup is safe to run any number of times.
- **The user's files are created only when missing, never overwritten:** rules, data, reports.
- **The plugin's own files are always refreshed:** the helper scripts and report template in `tools/`, `.claude/settings.json`, and the version marker. User-specific permissions belong in `.claude/settings.local.json`, which setup never touches.

## Steps

1. **Check the folder.** If the current folder already has files and no `.claude/minivakond-version`, confirm with the user before turning it into a workspace. An empty folder needs no confirmation.

2. **Run the setup script** from the workspace folder:
   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/setup.ps1"`

   It does four things:
   - creates the folders and missing starter files (including `CLAUDE.md`)
   - refreshes the helper scripts and the report template in `tools/`, and `.claude/settings.json`
   - downloads the DuckDB command-line tool into `tools/` if it's missing
   - writes `.claude/minivakond-version`

   If the download fails (offline, or blocked by a company network), tell the user plainly and stop. Without it nothing else works.

3. **Build check.** Run `./tools/duckdb.exe data/work.duckdb -f data/build.sql`.
   - The first run installs the Excel and encodings add-ons, which needs internet once.
   - If the build fails, `data/work.duckdb` is disposable: delete it and retry once.
   - If it still fails, the error is almost always in a block in `load.sql` or `views.sql`. Show the user which dataset or rule broke, in plain words, and offer to fix it.

4. **New workspace only:** the permission settings in `.claude/settings.json` take effect from the next session. Until then, the user may see a few approval prompts.

5. **Report**, in the user's language (Hungarian by default). Give a one-line status ("Minden kész — jöhet az első fájl!" or what was fixed or updated). If this is a new workspace, briefly explain how to work here:
   - drop spreadsheets into the `inbox` folder, or attach them in the chat
   - ask questions in their own words
   - you'll ask about anything ambiguous and remember the answers
