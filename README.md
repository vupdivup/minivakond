<p align="center"><img src="docs/logo.svg" width="160" alt="Minivakond logo: a red mole peeking out of the ground"></p>

# Minivakond

A Claude Code plugin that lets Hungarian business users ask plain-language questions about their CSV and Excel files. Windows only.

## Getting started

1. Install the plugin:

   ```
   /plugin marketplace add vupdivup/minivakond
   ```

   ```
   /plugin install minivakond@minivakond
   ```

   Run `/plugin marketplace update minivakond` later to get new versions.
2. Open an empty folder in the **Code** tab and say *„állítsd be”* ("set it up").
3. Drop a spreadsheet into `inbox/` (or attach it) and start asking questions.

## How it works

1. Setup creates a workspace in your folder and downloads [DuckDB](https://duckdb.org/).
2. Each new file is copied into `data/raw/` unchanged and loaded into the database.
3. Claude asks about anything ambiguous in the data and saves each answer as a business rule.
4. Every answer comes from a query that was actually run, applies the saved rules, and lists its assumptions. Answers can be chat tables, HTML charts and reports, or Excel exports.

## Skills

| Skill | Role |
|---|---|
| `workspace` | Conventions and session-start routine. Every other skill loads it first. |
| `setup` | Creates or repairs a workspace. Safe to re-run. |
| `ingest` | Loads a CSV or Excel file and handles Hungarian CSV quirks. |
| `clarify` | Finds ambiguities in the data and records the answers as business rules. |
| `report` | Answers questions with tables, charts, reports and Excel exports. |
