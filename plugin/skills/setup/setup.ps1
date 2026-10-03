# Creates or repairs a Minivakond workspace in the current folder.
# Safe to re-run: user files (rules, data, reports) are only created when missing;
# plugin-owned files (tools/*.ps1, tools/report_template.html, .claude/minivakond-version)
# are always refreshed.
$ErrorActionPreference = 'Stop'
$assets  = Join-Path $PSScriptRoot 'assets'
$root    = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$version = (Get-Content (Join-Path $root '.claude-plugin\plugin.json') -Raw | ConvertFrom-Json).version
$utf8    = New-Object System.Text.UTF8Encoding($false)  # no BOM

foreach ($d in 'inbox', 'data\raw', 'rules', 'reports', 'tools', '.claude') {
    New-Item -ItemType Directory -Force $d | Out-Null
}

# User-owned starter files: create only if missing.
$starters = 'data\load.sql', 'data\build.sql', 'rules\views.sql', 'rules\business_rules.md',
            'reports\log.md', '.claude\settings.json'
foreach ($f in $starters) {
    if (-not (Test-Path $f)) { Copy-Item (Join-Path $assets $f) $f; "created  $f" }
}

# CLAUDE.md: create, or append the pointer if an unrelated CLAUDE.md exists.
$pointer = Get-Content (Join-Path $assets 'CLAUDE.md.tmpl') -Raw -Encoding UTF8
if (-not (Test-Path 'CLAUDE.md')) {
    [IO.File]::WriteAllText("$PWD\CLAUDE.md", $pointer, $utf8); "created  CLAUDE.md"
} elseif (-not ((Get-Content 'CLAUDE.md' -Raw -Encoding UTF8) -match 'minivakond:workspace')) {
    [IO.File]::AppendAllText("$PWD\CLAUDE.md", "`n`n$pointer", $utf8); "updated  CLAUDE.md"
}

# Plugin-owned helper scripts and report template: always refresh.
Copy-Item (Join-Path $assets 'tools\*') 'tools' -Force
"refreshed tools\"

if (-not (Test-Path 'tools\duckdb.exe')) {
    "installing duckdb..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File 'tools\install_duckdb.ps1'
    if ($LASTEXITCODE -ne 0) { throw "DuckDB download failed" }
}

[IO.File]::WriteAllText("$PWD\.claude\minivakond-version", $version, $utf8)
"workspace version $version"
