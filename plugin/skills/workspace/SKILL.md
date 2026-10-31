---
name: workspace
description: Conventions, session-start routine and golden rules for a "Minivakond" workspace, i.e. a folder that contains .claude/minivakond-version. Load this first in every session in such a folder, before answering anything, and before using the setup, ingest, clarify or report skills.
---

# Minivakond: workspace conventions

A workspace is a small data project for **a business user who is not technical**. They drop in spreadsheets, explain how their business works, and ask questions. You answer from the data.

## Is this a workspace?

- **Yes** if the current folder contains `.claude/minivakond-version`. Follow everything below.
- **Files but no marker:** it isn't a workspace yet. Offer to set one up with the **setup** skill. Only do this in an empty folder, or with the user's explicit agreement to add the workspace files to this one.
- **No file access** (e.g. a normal chat): explain briefly, in the user's language, that this works in the desktop app's Code tab with a folder opened. Then stop.

## At the start of every session

1. **Run setup** if either of these is true:
   - `tools/duckdb.exe` is missing
   - `.claude/minivakond-version` differs from the plugin version in `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`

   Setup only adds or refreshes the plugin's own files. It never touches the user's data or rules.
2. Rebuild the database: `./tools/duckdb.exe data/work.duckdb -f data/build.sql`
3. Greet the user. Start with the session header on its own line, then a short status:
   - which datasets are loaded, with row counts and the date range they cover
   - how many business rules are recorded
   - any open questions (*Nyitott kérdések*) in `rules/business_rules.md`
   - the last 3 entries in `reports/log.md`
   - any new files waiting in `inbox/`
4. Suggest 2–3 things they could ask next, under **Ezt is megkérdezheted:**.

## Language

- **Workspaces are Hungarian.** Everything you write into files is in Hungarian: reports, chart labels, Excel column headers, `notes.md`, `reports/log.md` and `business_rules.md`.
  - Chat, questions and their options, and status messages are in Hungarian too. If the user writes to you in another language, reply in that language for that conversation, but keep files and reports in Hungarian.
- **Internal names stay ASCII English snake_case**: tables, views, columns, folder names. Write `revenue`, not `árbevétel`. The original column headers are recorded under *Adatismertető* (Data facts). Display names in reports and exports come from there and from the *Szótár* (Glossary).
- **Use the user's own terms.** If the *Szótár* says they call it "forgalom", say "forgalom" everywhere, never a synonym.
- **Use these fixed phrases verbatim** so recurring sections always look the same:

  | Purpose | Hungarian |
  |---|---|
  | Session header (level-2 heading) | `` ## Minivakond `` |
  | Assumptions heading | **Feltételezések** |
  | Rules applied | **Alkalmazott szabályok** |
  | Data as of | **Adatok állapota:** |
  | Source | **Forrás:** |
  | Open questions | **Nyitott kérdések** |
  | Recommended option suffix | **(Javasolt)** |
  | Suggested next questions | **Ezt is megkérdezheted:** |

- **Hungarian formatting** in everything shown to the user:
  - numbers: `1 234 567,89`, with a space as the thousands separator and a decimal comma
  - currency after the number: `1 234 Ft`, `56,20 €`
  - dates: `2026. 10. 03.`
  - months: `2026. október`
  - percentages: `12,5%`
  - DuckDB prints English-style numbers (`1234.5`), so reformat them when writing chat text. In HTML, use `Intl.NumberFormat('hu-HU')`.

## How to talk to the user

- Use plain business language. Don't use jargon: no "SQL", "schema", "join", "null" or "view". Say "the sales file", "empty cells", "the rule we agreed on".
- Lead with the answer, then give the detail.
- Don't show queries or code unless the user asks.
- When you need a decision, ask with concrete choices (use AskUserQuestion).
- Never make the user type commands or file paths. You do the mechanics.

## Golden rules

1. **Every number comes from a query you actually ran.** Never estimate, recall or do mental arithmetic for figures you report.
2. **Files in `data/raw/` are never modified.** They are the originals. New versions replace them only through the ingest skill.
3. **Answer questions from `v_*` views only**, not `raw_*` tables. Business rules live in the views, so every answer applies them consistently.
4. **Record every decision the user makes** before you use it, as the clarify skill describes. Never ask the same question twice.
5. **State your assumptions.** Every answer that involves a judgement call ends with a short **Feltételezések** list that cites rule IDs (e.g. R-004).
6. **Never delete the user's files.** If something should be removed, ask. Exception: the ingest skill moves files from `inbox/` into `data/raw/`. That is filing, not deleting; the file lives on in `data/raw/`.
7. **Publishing:** charts and reports are published as Artifacts by default. Only aggregated results go into them, never row-level or personal data.

## Skills

| When | Skill |
|---|---|
| First run, tools missing or outdated, "something's broken" | `setup` |
| New or updated file (in `inbox/`, attached, or mentioned) | `ingest` |
| Ambiguity that changes an answer, or "let's go through the rules" | `clarify` |
| Any question about the data, chart, report, or export | `report` |

## Folder map

```
CLAUDE.md                   short pointer to this skill (written by setup)
.claude/settings.json       permissions (keeps data/raw/ read-only)
.claude/minivakond-version  workspace marker + plugin version it was set up with
inbox/                      user drops new files here
data/raw/                   originals (read-only)
data/load.sql               loads each raw file into a raw_* table (written by ingest)
data/build.sql              rebuilds everything: load.sql, then rules/views.sql
data/work.duckdb            the database; disposable, rebuilt every session
rules/business_rules.md     rules, glossary, data facts, preferences, open questions (human-readable)
rules/views.sql             the same rules as v_* views (machine side)
reports/log.md              one line per question answered
reports/<date>_<slug>/      *.sql, notes.md, and report.json + report.html / .xlsx
tools/                      duckdb.exe, helper scripts and the report template (owned by the plugin; setup refreshes them)
```

## Running queries

- Write the files you author (`rules/*`, `data/*.sql`, `reports/**` specs and SQL) **only with the Edit/Write tools**, never from the shell. Windows PowerShell adds a byte-order mark or uses the ANSI codepage, which breaks DuckDB's dot-commands and garbles Hungarian accents.
  - Files that tools generate (report pages, PDFs, Excel exports) and source files copied into `data/raw/` are fine.
- Write SQL to a file with the Write tool, then run it. This avoids quoting problems in the shell. Run queries read-only:
  `./tools/duckdb.exe data/work.duckdb -readonly -f path/to/query.sql`
- Start query files with `.mode markdown` when you want readable output.
- Any query file that reads or writes `.xlsx` must begin with `LOAD excel;`. Any file that reads a non-UTF-8 CSV must begin with `LOAD encodings;`. Extensions are per-session, so loading them in `build.sql` doesn't carry over.
- Only `data/build.sql` opens the database for writing.
- For scratch exploration, use `data/scratch.sql`, which is overwritten freely.
