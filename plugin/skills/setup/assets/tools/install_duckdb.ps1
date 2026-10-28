# Downloads a pinned DuckDB CLI release for Windows into tools/duckdb.exe.
# Pinned rather than "latest": v2.0.0 renamed the release assets, which broke the "latest" URL.
$ErrorActionPreference = 'Stop'
$version = 'v2.0.0'
$tools = Join-Path (Get-Location) 'tools'
New-Item -ItemType Directory -Force $tools | Out-Null

$arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'amd64' }
$url  = "https://github.com/duckdb/duckdb/releases/download/$version/duckdb-cli-windows-$arch.tar.gz"
$archive = Join-Path $env:TEMP "duckdb_cli.tar.gz"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
# Windows' own tar.exe (Windows 10 1803+); a Git for Windows tar earlier on PATH can't handle C:\ paths.
& (Join-Path $env:SystemRoot 'System32\tar.exe') -xzf $archive -C $tools duckdb.exe
if ($LASTEXITCODE -ne 0) { throw "tar failed to extract $archive" }
Remove-Item $archive
Unblock-File (Join-Path $tools 'duckdb.exe')

& (Join-Path $tools 'duckdb.exe') -version
