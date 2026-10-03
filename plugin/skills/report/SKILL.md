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
  - Saved reports: use `reports/<YYYY-MM-DD>_<slug>/query.sql`.
- **Sanity-check before answering:**
  - Do parts add up to the total?
  - Is the row count plausible?
  - How many rows were excluded by filters or empty values?
  - Is the date range what the user meant?

## 3. Pick the output: the lightest one that does the job

| Need | Output |
|---|---|
| A number or a small table (≲ 15 rows) | Markdown table in the chat. No files. |
| A trend, comparison or breakdown | HTML chart page (see 4) |
| A multi-section report | HTML report page (see 4) |
| "Put it in Excel" / data to work with | `LOAD excel;` then `COPY (SELECT ...) TO 'reports/<folder>/<name>.xlsx' WITH (FORMAT xlsx, HEADER true);` (works with `-readonly`) |

**Excel exports:**
- Give columns Hungarian headers with quoted aliases, e.g. `net_revenue AS "Nettó árbevétel (Ft)"`. Take the wording from the *Szótár* or the original headers in the *Adatismertető*.
- Keep the values numeric, not formatted text, so Hungarian Excel displays them in its own locale.
- Never export CSV for the user: Hungarian Excel misreads comma-separated files.

## 4. HTML charts and reports

1. Copy `${CLAUDE_SKILL_DIR}/template.html` into the report folder as `report.html` and fill in the `DATA` block:
   - title, subtitle (data as-of and source)
   - KPI tiles
   - charts: Chart.js, with data inlined as JSON
   - table
   - assumptions

   All text is in Hungarian. Put **raw numbers** in `DATA` (`124000000`, not `"124 000 000 Ft"`). The template formats them with `hu-HU` locale using each value's `fmt`: `"ft"`, `"eur"`, `"num"`, `"pct"` or `"date"`.
2. Keep it self-contained: no external files other than the Chart.js CDN script already in the template.
3. **Show it:**
   - Publish `report.html` as an Artifact. Follow the Artifact tool's own instructions (it may ask you to load design guidance first). Updating a recurring report republishes to the same file path, which keeps the same link.
   - If the Artifact tool isn't available or publishing fails, open it locally: `start reports/<folder>/report.html` (Bash) or `Invoke-Item reports/<folder>/report.html` (PowerShell).
   - **Only aggregated numbers go into published pages.** No row-level or personal data, ever.

## 5. Record

- For saved reports, write `notes.md` in the report folder, in Hungarian, covering:
  - the question in the user's words
  - rules applied (R-IDs)
  - assumptions
  - data as-of date
  - row counts
  - the artifact link, if published
- Append one line to `reports/log.md` for every answered question, including quick ones:
  `<date> — <question> — <one-line answer> — <folder or "chat">`

## 6. Reply

Reply in Hungarian, with Hungarian number and date formatting, using the user's own terms from the *Szótár*.

1. Headline: the answer in one or two sentences, with the key number.
2. The table, chart link, or file location.
3. **Feltételezések:** a short bullet list with R-IDs. Omit it if there were none.
4. One natural follow-up suggestion.
