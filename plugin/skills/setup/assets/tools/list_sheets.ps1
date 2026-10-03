# Lists the sheet names of an .xlsx file (DuckDB can't list them itself).
param([Parameter(Mandatory)][string]$Path)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path $Path))
try {
    $entry = $zip.GetEntry('xl/workbook.xml')
    $reader = New-Object IO.StreamReader($entry.Open())
    [xml]$wb = $reader.ReadToEnd()
    $reader.Close()
    $wb.workbook.sheets.sheet | ForEach-Object { $_.name }
} finally {
    $zip.Dispose()
}
