---
name: ingest
description: In a "Minivakond" workspace, loads a new or updated CSV or Excel file and makes sure its contents are understood. Use when files appear in inbox/, when the user attaches or mentions a spreadsheet, or says things like "here's the new data", "I have an export", "updated numbers for this month", "itt az új adat", "feltöltöttem egy táblázatot", "itt a havi export", "frissítettem a fájlt", "új excel".
---

# Ingest a file

Follow the `workspace` skill's conventions; load it first if it isn't loaded yet. If the current folder isn't a workspace (no `.claude/minivakond-version`), do what that skill's "Is this a workspace?" section says instead.

The goal is a clean `raw_<name>` table, a `v_<name>` view, and a shared understanding of what the data means. Getting the meaning right matters more than loading fast.

## 1. Locate and place the file

- Sources: `inbox/`, a file the user attached, or a path they mention.
- Choose a short snake_case dataset name (e.g. `sales`, `customers`). Confirm it only if it's unclear.
- **Same dataset already exists?** Ask whether this file **replaces** it (e.g. a refreshed full export) or **adds to** it (e.g. a new month).
  - Replace: copy it over the file it replaces.
  - Add: every file of the dataset lives in `data/raw/<name>/` as `<name>_<period>.<ext>`, e.g. `sales/sales_2026-10.xlsx`. `<period>` is the period the file covers.
    - **First add only:** the dataset is still a single file at `data/raw/<name>.<ext>`. Move it into the folder first: create `data/raw/<name>/` (`New-Item -ItemType Directory -Force`), then `Move-Item 'data/raw/<name>.<ext>' 'data/raw/<name>/<name>_<period>.<ext>'`. Take its period from its date column, and ask the user only if it has none. If you skip this, the first period drops out of the load.
    - Then place the new file in the folder and update the dataset's block in `data/load.sql` to read all of the folder's files (see step 3).
- Place the file in `data/raw/` from the shell, without asking the user:
  - A file from `inbox/` is moved (`Move-Item`), so the inbox shows only pending files. This is filing, not deleting (golden rule 6).
  - A file already in `data/raw/` is moved (`Move-Item`) too: the first-add case above. Its contents stay unchanged.
  - A file from anywhere else is copied (`Copy-Item`) and stays where it is.
  - Don't use Edit/Write for `data/raw/`. The workspace settings deny them there, and Write can't copy a binary `.xlsx`.

## 2. Look at the raw layout before trusting it

- **CSV:** run `DESCRIBE SELECT * FROM read_csv('data/raw/x.csv')` and look at 10 rows. Hungarian exports (Excel, Számlázz.hu, ERP and bank systems) commonly differ from the defaults in four ways, so check each one explicitly:
  1. **Encoding.**
     - If DuckDB reports "not utf-8 encoded", or the text shows garbage where ő/ű/á should be, the file is most likely Windows-1250.
     - Fix: `LOAD encodings;` and `encoding='cp1250'`. Use exactly that name; `windows-1250` is not recognised.
     - Check the result: names like *Őrség*, *Kűrt* or *Árbevétel* must come out intact. Latin-1 silently turns ő/ű into õ/û, so look for that too.
  2. **Delimiter:** usually `;` (`delim=';'`).
  3. **Decimal comma:** `decimal_separator=','`.
     - Check that amount columns came out as numbers, not VARCHAR.
     - Thousands separators (space or `.`) inside numbers need cleaning in SQL: `replace(replace(col, ' ', ''), '.', '')`, then cast.
  4. **Dates:** `2026.10.03.` needs `dateformat='%Y.%m.%d.'`. The variant without the trailing dot needs `'%Y.%m.%d'`; with spaces, `'%Y. %m. %d.'`.
- Verified working example:
  `read_csv('data/raw/x.csv', encoding='cp1250', delim=';', decimal_separator=',', dateformat='%Y.%m.%d.')`
- **Excel:**
  1. List the sheets: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/list_sheets.ps1 data/raw/x.xlsx`
  2. Pick the data sheet, asking only if several look plausible.
  3. Read the top as plain text to see the true layout:
     `SELECT * FROM read_xlsx('data/raw/x.xlsx', sheet='S', header=false, all_varchar=true, range='A1:Z25')`
  4. Watch for: title rows above the header, multi-row headers, merged cells, subtotal/total rows, notes at the bottom, and blank spacer columns. Use `range=` to skip the junk.

Explore in `data/scratch.sql`, run as the workspace skill's "Running queries" describes.

## 3. Load

1. Write the dataset's block in `data/load.sql`: a one-line comment saying what the dataset is and its layout quirks, then `CREATE OR REPLACE TABLE raw_<name> AS SELECT ...`.
   - **One block per dataset.** For a new dataset, append a block. For a replaced or added file, update the existing block. A second `CREATE OR REPLACE TABLE raw_<name>` would silently overwrite the first.
   - **Folder of period files:**
     - CSV: one `read_csv('data/raw/<name>/*.csv', union_by_name = true, ...)` reads them all.
     - Excel: `read_xlsx` given a glob silently reads only the first matching file. Write one `read_xlsx` per file and join them with `UNION ALL BY NAME`; add a line for each new period.
   - Keep cleaning minimal here: fix types and skip junk rows.
   - **Rename every column to ASCII English snake_case** with `AS`, e.g. `"Számla kelte" AS invoice_date`, `"Nettó összeg" AS net_amount`. Accented and space-containing names break queries.
   - Record each mapping (original header → internal name → meaning) under *Adatismertető*, so reports can show the user's original wording.
   - Excel numbers always arrive as decimals (DOUBLE). Cast ID and count columns to integer, and IDs with leading zeros to text.
   - Business meaning goes in views, not here.
2. If `v_<name>` doesn't exist yet, add a pass-through view to `rules/views.sql`: `CREATE OR REPLACE VIEW v_<name> AS SELECT * FROM raw_<name>;`
3. Rebuild: `./tools/duckdb.exe data/work.duckdb -f data/build.sql`

## 4. Profile

Run `SUMMARIZE raw_<name>` plus a row count. Then look for problems through the "Where ambiguity hides" lenses in the clarify skill (`${CLAUDE_PLUGIN_ROOT}/skills/clarify/SKILL.md`), querying wherever a lens plausibly applies to this data. Check that the date range matches what the user expects. For a dataset with period files, count rows per period and check that every file shows up.

Then work out what this file can and cannot answer. For example, rates or per-person averages need a full population, and "remaining" or "vs. target" questions need a budget, target or entitlement. Note what's missing.

## 5. Confirm meaning with the user

- Give a short plain-language summary in the user's language: how many rows, what one row is, the period covered, and the number of columns.
- Include a 5-row preview as a markdown table, using the **original** column headers and the user's number and date formatting.
- Ask only about columns whose meaning is genuinely unclear. Don't ask about obvious ones.
- Tell the user what the file can answer and, briefly, what it can't without additional data.
- Write what you learned under *Adatismertető* (data facts) in `rules/business_rules.md`, in Hungarian: source, grain (what one row is), column mapping and meanings, quirks, file encoding, coverage gaps.
- Problems from step 4 that affect calculations go to the **clarify** skill. Batch them; don't fire them one by one.

## 6. Close

Tell the user the data is ready and suggest 2–3 questions they could ask of it, under **Ezt is megkérdezheted:**.
