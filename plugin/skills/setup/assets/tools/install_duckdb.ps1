# Downloads the latest DuckDB CLI for Windows into tools/duckdb.exe.
$ErrorActionPreference = 'Stop'
$tools = Join-Path (Get-Location) 'tools'
New-Item -ItemType Directory -Force $tools | Out-Null

$arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'amd64' }
$url  = "https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-windows-$arch.zip"
$zip  = Join-Path $env:TEMP "duckdb_cli.zip"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $tools -Force
Remove-Item $zip
Unblock-File (Join-Path $tools 'duckdb.exe')

& (Join-Path $tools 'duckdb.exe') -version
