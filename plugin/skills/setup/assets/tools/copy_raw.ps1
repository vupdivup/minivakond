# Copies a source file into data/raw/ (the Edit/Write tools are denied there).
# Run from the workspace folder. A source inside inbox/ is moved (removed after the copy),
# so the inbox lists only pending files. Any other source stays where it is.
param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$Destination
)
$ErrorActionPreference = 'Stop'

$rawRoot   = [IO.Path]::GetFullPath((Join-Path $PWD 'data\raw')).TrimEnd('\') + '\'
$inboxRoot = [IO.Path]::GetFullPath((Join-Path $PWD 'inbox')).TrimEnd('\') + '\'
$src  = (Resolve-Path -LiteralPath $Source).Path
$dest = [IO.Path]::GetFullPath((Join-Path $PWD $Destination))

if (-not $dest.StartsWith($rawRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Destination must be inside data\raw\: $dest"
}

New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
Copy-Item -LiteralPath $src -Destination $dest -Force
"copied   $src -> $dest"

if ($src.StartsWith($inboxRoot, [StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item -LiteralPath $src
    "removed  $src"
}
