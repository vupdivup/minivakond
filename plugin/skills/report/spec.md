# `report.json` format

`tools/build_report.ps1` reads `report.json`, runs every SQL file it names, and writes `report.html` next to it. The page is rendered from `tools/report_template.html`. Every number on the page comes from a query result. The spec holds only text and layout.

## Top level

| Key | Required | Meaning |
|---|---|---|
| `title` | yes | Page title, in Hungarian. |
| `asOf` | no | Data as-of date, `"YYYY-MM-DD"`. Shown as "Adatok állapota". |
| `source` | no | Source file name or description. Shown as "Forrás". |
| `kpis` | no | KPI tiles; see below. Leave out unless the user asked for a report. |
| `sections` | yes | Ordered list of sections; see below. |
| `assumptions` | no | List of strings, each citing rule IDs. Rendered under "Feltételezések". |

Parts that are left out don't render at all, including their headings.

## SQL files

- One file per dataset, in the report folder. Every `sql` value is a file name relative to `report.json`.
- Each file holds **exactly one `SELECT`**. No `.mode` or other dot commands, no `LOAD`, no second statement. The script runs it with `-readonly -json` itself.
- Results are capped at 500 rows. A larger result means the data isn't aggregated enough for a published page.
- Name columns in ASCII snake_case. Display names go in the spec.
- Compute percentages as fractions in SQL (`0.342`, not `34.2`). The `pct` format multiplies by 100.
- Several parts may share one SQL file.

## Formats (`fmt`)

`"ft"` (124 000 000 Ft), `"eur"` (30 224,29 €), `"num"`, `"pct"` (0.342 → 34,2%), `"date"` (2026. júl. 31.), `"month"` (2026. júl.). Without `fmt`, the value is shown as is.

## `kpis`

```json
"kpis": { "sql": "kpis.sql", "items": [
  { "col": "revenue", "label": "Nettó árbevétel", "fmt": "ft" },
  { "col": "share", "label": "Higiénia részaránya", "fmt": "pct",
    "delta": { "col": "share_h1", "fmt": "pct", "text": "az I. félévben" } }
] }
```

- The query returns one row. Each item shows one of its columns. Use 2–4 items.
- `delta` is an optional small line under the value. It is either a plain string without figures, or `{ col, fmt, text }`, which shows the column value followed by `text`.

## `sections`

Each section is an object with any of: `heading`, `text` (a short paragraph), `chart`, `table`.

- `heading` states the main finding, e.g. "Februárban volt a csúcs", not "Havi árbevétel".
- Any figures in `heading` or `text` must come from query results you ran.

### `chart`

```json
"chart": { "type": "bar", "sql": "by_month.sql", "x": "period_month", "xFmt": "month",
           "series": [ { "col": "huf", "name": "Nettó árbevétel" } ], "fmt": "ft" }
```

| Key | Meaning |
|---|---|
| `type` | `"bar"`, `"line"` or `"doughnut"`. |
| `sql`, `x` | Query and the column for the labels (x axis, or doughnut slices). |
| `xFmt` | Format for the labels, e.g. `"month"` for a `period_month` date column. |
| `series` | One entry per series: `{ col, name }`. Optional per series: `"type": "line"` (a line over bars) and `"axis": "y2"` (right-hand axis). |
| `groupBy` | For long-format rows (one row per x value and group). Gives one series per distinct value of this column; `series` then holds a single `{ col }`. |
| `fmt` | Value format for the axis and tooltips. `fmt2` is the format of the `y2` axis. |
| `stacked` | `true` stacks the series. |
| `horizontal` | `true` for horizontal bars; use for long category names or rankings. No `y2` with horizontal. |
| `beginAtZero` | `false` lets the value axis start above zero (line charts only). |

Order the rows in SQL; the chart keeps the query's order.

### `table`

```json
"table": { "sql": "by_region.sql", "totalRow": true, "columns": [
  { "col": "region", "label": "Régió" },
  { "col": "huf", "label": "Nettó árbevétel (Ft)", "fmt": "ft" } ] }
```

- Columns with a numeric `fmt` are right-aligned.
- `totalRow: true` highlights the last row. Produce that row in SQL, e.g. with `GROUP BY ROLLUP` or `UNION ALL`.

## Examples

A chart page (one chart, nothing else):

```json
{ "title": "Havi nettó árbevétel, 2026. január – július", "asOf": "2026-07-31", "source": "ertekesites_2026.csv",
  "sections": [ { "chart": { "type": "line", "sql": "monthly.sql", "x": "period_month", "xFmt": "month",
                             "series": [ { "col": "huf", "name": "Nettó árbevétel" } ], "fmt": "ft" } } ],
  "assumptions": [ "Az árbevétel nettó, sztornók nélkül (R-001)." ] }
```

A report page adds `kpis` and further sections with `heading`s, charts and tables.
