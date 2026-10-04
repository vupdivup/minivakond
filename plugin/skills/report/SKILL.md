---
name: report
description: In a "Minivakond" workspace, answers questions about the user's data and produces tables, charts, reports and Excel exports. Use for any question about the user's data ("what were sales last month", "top customers", "compare regions", "make me a chart", "export this to Excel", "build a monthly report", "mennyi volt a forgalom", "kik a legnagyobb vevők", "hasonlítsd össze", "csinálj egy diagramot", "tedd ki Excelbe", "havi kimutatás", "riport").
---

# Answer a question / build a report

Follow the `workspace` skill's conventions; load it first if it isn't loaded yet. If the current folder isn't a workspace (no `.claude/minivakond-version`), do what that skill's "Is this a workspace?" section says instead.

## 1. Understand the question

- Re-read `rules/business_rules.md` for definitions the question touches.
- If a word in the question maps to more than one plausible calculation and no rule covers it, use the **clarify** skill before answering. Ask only if the choice changes the result materially; otherwise pick the sensible option and list it under Assumptions.
- Vague time ranges ("recently", "this year") get the obvious interpretation, stated in the answer. Don't ask about them.

## 2. Query

- Query `v_*` views only. If you need logic that isn't in a view yet and it's a business rule, it belongs in `views.sql` (via clarify), not buried in a one-off query.
- Write the SQL to a file and run it read-only:
  `./tools/duckdb.exe data/work.duckdb -readonly -f <file>.sql`
  - Quick answers: use `data/scratch.sql`.
  - Chart and report pages: use one file per dataset in `reports/<YYYY-MM-DD>_<slug>/`, e.g. `by_month.sql`. Each holds exactly one `SELECT` and no dot commands (see 4). Run them once with `.mode markdown` from `data/scratch.sql` if you want to read the results first.
- **Sanity-check before answering:**
  - Do parts add up to the total?
  - Is the row count plausible?
  - How many rows were excluded by filters or empty values?
  - Is the date range what the user meant?

## 3. Pick the output: the lightest one that does the job

| Need | Output |
|---|---|
| A number or a small table (≲ 15 rows) | Markdown table in the chat. No files. |
| A trend, comparison or breakdown, or "make a chart" | Chart page: one chart, nothing else (see 4) |
| "Make a report", a monthly summary, several views at once | Report page: KPIs, several charts and tables (see 4) |
| "Put it in Excel" / data to work with | `LOAD excel;` then `COPY (SELECT ...) TO 'reports/<folder>/<name>.xlsx' WITH (FORMAT xlsx, HEADER true);` (works with `-readonly`) |

**Excel exports:**
- Give columns Hungarian headers with quoted aliases, e.g. `net_revenue AS "Nettó árbevétel (Ft)"`. Take the wording from the *Szótár* or the original headers in the *Adatismertető*.
- Keep the values numeric, not formatted text, so Hungarian Excel displays them in its own locale.
- Never export CSV for the user: Hungarian Excel misreads comma-separated files.

## 4. HTML charts and reports

**The template is the design.** Every page uses `tools/report_template.html`, unchanged. You never write or edit HTML, CSS or JavaScript for a report, and you never type numbers into the page.

**Deliver what was asked.** A chart request gets a chart page: one section with one chart, plus title, as-of date and assumptions. No KPIs, extra charts or tables. Offer those as the follow-up suggestion (6.4) instead.

1. Read `${CLAUDE_SKILL_DIR}/spec.md` for the spec format.
2. Write the SQL files (see 2) and `reports/<folder>/report.json` with the Write tool. All text in the spec is Hungarian, with the user's terms from the *Szótár*.
3. Build the page:
   `powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_report.ps1 reports/<folder>/report.json`
   - It prints the row count of each query; check them as in 2.
   - If it fails, fix the spec or the SQL and run it again. If the page can't express what the user wants, tell the user instead of editing `report.html`.
4. **Show it:**
   - Publish `report.html` as an Artifact. Don't call the Artifact tool's `quickstart` and don't load `artifact-design` or other design guidance for reports: their generic advice doesn't apply to this page. The template's own `<!doctype>`/`<head>`/`<body>` skeleton is intentional; keep it. Updating a recurring report means re-running the build and republishing the same file path, which keeps the same link.
   - After publishing, always call the Artifact tool with `action: "open"` and the URL from the publish result, so the page shows without a click. This overrides the tool's default guidance that a fresh publish needs no `open`.
   - If the Artifact tool isn't available or publishing fails, open it locally: `start reports/<folder>/report.html` (Bash) or `Invoke-Item reports/<folder>/report.html` (PowerShell).
   - **Only aggregated numbers go into published pages.** No row-level or personal data, ever.

## 5. Record

- For chart and report pages and Excel exports, write `notes.md` in the report folder, in Hungarian, covering:
  - the question in the user's words
  - rules applied (R-IDs)
  - assumptions
  - data as-of date
  - row counts
  - the artifact link, if published
- Append one line to `reports/log.md` for every answered question, including quick ones:
  `<date> — <question> — <one-line answer> — <folder or "chat">`

## 6. Reply

Reply in Hungarian (or in the user's language if they write in another one), with Hungarian number and date formatting, using the user's own terms from the *Szótár*.

1. Headline: the answer in one or two sentences, with the key number.
2. The table, chart link, or file location.
3. **Feltételezések:** a short bullet list with R-IDs. Omit it if there were none.
4. One natural follow-up suggestion.
