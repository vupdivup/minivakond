# Packages plugin/ as dist/minivakond-<version>.plugin (a zip with .claude-plugin/plugin.json at its root).
# Upload it in the desktop app: Customize > Plugins > Add > Upload plugin.
# If the upload is rejected, rename the file to .zip; it's the same format.
#
#   powershell -File scripts/build.ps1
$ErrorActionPreference = 'Stop'
$src = Resolve-Path (Join-Path $PSScriptRoot '..\plugin')
$dist = Join-Path $PSScriptRoot '..\dist'
$version = (Get-Content (Join-Path $src '.claude-plugin\plugin.json') -Raw | ConvertFrom-Json).version

New-Item -ItemType Directory -Force $dist | Out-Null
$out = Join-Path (Resolve-Path $dist) "minivakond-$version.plugin"
if (Test-Path $out) { Remove-Item $out }

# Compress-Archive skips dot-folders like .claude-plugin when given a wildcard, so build
# the zip with forward-slash entry names directly.
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($out, 'Create')
try {
    Get-ChildItem $src -Recurse -Force -File | ForEach-Object {
        $rel = $_.FullName.Substring($src.Path.Length + 1).Replace('\', '/')
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $rel) | Out-Null
    }
} finally { $zip.Dispose() }

Write-Host "Built: $out"
