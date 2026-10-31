# Builds a self-contained report page from a report spec (report.json) and its SQL files.
# Every number on the page comes straight from DuckDB's JSON output; nothing is retyped.
# Usage: tools/build_report.ps1 reports/<folder>/report.json  ->  reports/<folder>/report.html
param(
    [Parameter(Mandatory)][string]$Spec,
    [int]$MaxRows = 500
)
$ErrorActionPreference = 'Stop'
$duckdb = Join-Path $PSScriptRoot 'duckdb.exe'
$db     = Join-Path (Split-Path $PSScriptRoot -Parent) 'data\work.duckdb'
$utf8   = New-Object System.Text.UTF8Encoding($false)  # no BOM
[Console]::OutputEncoding = $utf8                      # decode duckdb's output as UTF-8

$specPath = (Resolve-Path $Spec).Path
$dir      = Split-Path $specPath -Parent
$outPath  = [IO.Path]::ChangeExtension($specPath, '.html')
$specText = [IO.File]::ReadAllText($specPath)
try { $s = $specText | ConvertFrom-Json } catch { throw "$Spec is not valid JSON: $($_.Exception.Message)" }

# Every SQL file the spec references, in order.
$sqlFiles = @()
function Add-Sql($part, $where) {
    if (-not $part) { return }
    if (-not $part.sql) { throw "$where has no `"sql`" file" }
    $script:sqlFiles += $part.sql
}
Add-Sql $s.kpis 'kpis'
$i = 0
foreach ($sec in @($s.sections)) {
    $i++
    Add-Sql $sec.chart "sections[$i].chart"
    Add-Sql $sec.table "sections[$i].table"
}
$sqlFiles = @($sqlFiles | Select-Object -Unique)

# Run each query read-only and keep its JSON output verbatim (no number parsing in PowerShell).
$results = foreach ($f in $sqlFiles) {
    $path = Join-Path $dir $f
    if (-not (Test-Path $path)) { throw "SQL file not found: $path" }
    $json = (& $duckdb -readonly -json $db -f $path) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Query failed: $f" }
    try { $parsed = ConvertFrom-Json $json } catch { $parsed = $null }
    if (-not $json.Trim().StartsWith('[') -or ($null -eq $parsed -and $json.Trim() -ne '[]')) {
        throw "$f must hold exactly one SELECT and no dot commands (.mode etc.)"
    }
    $count = @($parsed).Count
    if ($count -gt $MaxRows) {
        throw "$f returned $count rows (limit $MaxRows). Published pages hold aggregates only: group the data further."
    }
    "  $f`: $count rows" | Write-Host
    "$(ConvertTo-Json $f): $json"
}

# Build date for the footer; plugin version from the workspace marker, for <meta name="generator">.
$built   = Get-Date -Format 'yyyy-MM-dd'
$marker  = Join-Path (Split-Path $PSScriptRoot -Parent) '.claude\minivakond-version'
$version = if (Test-Path $marker) { ([IO.File]::ReadAllText($marker)).Trim() } else { '' }
$build   = ConvertTo-Json -Compress @{ date = $built; version = $version }

# '</' inside a JSON string would end the <script> block early; '<\/' is the same string.
$data = "const SPEC = $specText;`nconst RESULTS = {`n$($results -join ",`n")`n};`nconst BUILD = $build;" -replace '</', '<\/'
$tmpl = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'report_template.html'))
if ($tmpl -notmatch '(?s)// @@DATA.*// @@END') { throw 'report_template.html has no DATA markers; re-run setup' }
$html = [regex]::Replace($tmpl, '(?s)// @@DATA.*?// @@END',
    [Text.RegularExpressions.MatchEvaluator] { "// @@DATA`n$data`n// @@END" })
$title = [Net.WebUtility]::HtmlEncode($s.title)
$html = [regex]::Replace($html, '<title>.*?</title>',
    [Text.RegularExpressions.MatchEvaluator] { "<title>$title</title>" })
$generator = [Net.WebUtility]::HtmlEncode("Minivakond $version".Trim())
$html = [regex]::Replace($html, '<meta name="generator" content=".*?">',
    [Text.RegularExpressions.MatchEvaluator] { "<meta name=`"generator`" content=`"$generator`">" })

[IO.File]::WriteAllText($outPath, $html, $utf8)
"built $outPath"
