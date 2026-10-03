-- Rebuilds the whole database from the original files plus the business rules.
-- Run: ./tools/duckdb.exe data/work.duckdb -f data/build.sql
INSTALL excel;
LOAD excel;
INSTALL encodings;   -- non-UTF-8 CSVs, e.g. Windows-1250 (cp1250) Hungarian exports
LOAD encodings;
.read data/load.sql
.read rules/views.sql
