# Prints a report page to PDF with headless Microsoft Edge (ships with Windows 11).
# Unlike the desktop app's export, this is real print: CSS page breaks apply and text stays selectable.
# Usage: tools/export_pdf.ps1 reports/<folder>/report.html  ->  reports/<folder>/report.pdf
param(
    [Parameter(Mandatory)][string]$Page,
    [int]$WaitMs = 5000
)
$ErrorActionPreference = 'Stop'

$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
          "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { throw 'Microsoft Edge not found; open the page in a browser and print it to PDF instead' }

$pagePath = (Resolve-Path $Page).Path
$outPath  = [IO.Path]::ChangeExtension($pagePath, '.pdf')
$url      = ([Uri]$pagePath).AbsoluteUri
if (Test-Path $outPath) { Remove-Item $outPath }

# A throwaway profile keeps headless Edge apart from a running Edge window.
$edgeProfile = Join-Path ([IO.Path]::GetTempPath()) "minivakond-edge-$PID"
try {
    # The time budget lets the page script finish the chart snapshots before printing.
    $edgeArgs = @('--headless', '--disable-gpu', '--no-first-run', '--no-pdf-header-footer',
              "--user-data-dir=`"$edgeProfile`"", "--virtual-time-budget=$WaitMs",
              "--print-to-pdf=`"$outPath`"", "`"$url`"")
    Start-Process -FilePath $edge -ArgumentList $edgeArgs -Wait -WindowStyle Hidden
} finally {
    Remove-Item $edgeProfile -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $outPath) -or (Get-Item $outPath).Length -eq 0) { throw "Edge did not write $outPath" }
"exported $outPath"
