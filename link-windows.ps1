<#
.SYNOPSIS
  MiKTeX equivalent of `make link`.

.DESCRIPTION
  MiKTeX has no TEXMFHOME, so this registers a personal TEXMF root (default
  $HOME\texmf) and places symlinks to ou-refs.sty and ou-refs.bib in it, at
  the TDS paths MiKTeX and biber expect. Edits and `git pull` in this
  checkout then take effect immediately.

  Only those two files are exposed, never the whole checkout: MiKTeX indexes
  every file under a root, and a junction to the repo would make stray build
  products (example.aux and friends) visible to every document.

  File symlinks need Developer Mode or an elevated shell. Without either,
  the files are copied instead and you re-run this after each `git pull`.

.PARAMETER Root
  TEXMF root to register and link into. Default: $HOME\texmf

.PARAMETER Unlink
  Remove the links (or copies) instead. The root stays registered.

.EXAMPLE
  .\link-windows.ps1
  .\link-windows.ps1 -Unlink
#>
param(
    [string] $Root = (Join-Path $HOME 'texmf'),
    [switch] $Unlink
)

$ErrorActionPreference = 'Stop'
$name = 'ou-refs'

# TDS path => file in this checkout.
$files = @{
    "tex\latex\$name\$name.sty" = Join-Path $PSScriptRoot "$name.sty"
    "bibtex\bib\$name\$name.bib" = Join-Path $PSScriptRoot "$name.bib"
}

foreach ($rel in $files.Keys) {
    $path   = Join-Path $Root $rel
    $target = $files[$rel]
    if ($Unlink) {
        if (Test-Path $path) { Remove-Item $path; "removed $path" }
        continue
    }
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    if (Test-Path $path) { Remove-Item $path }
    try {
        New-Item -ItemType SymbolicLink -Path $path -Target $target -ErrorAction Stop | Out-Null
        "linked $path -> $target"
    } catch {
        Copy-Item $target $path
        "copied $target -> $path"
        "  (symlinks need Developer Mode or an elevated shell; re-run after git pull)"
    }
}

if ($Unlink) { miktex fndb refresh; return }

$registered = (initexmf --report) -match [regex]::Escape($Root)
if (-not $registered) { initexmf --register-root=$Root; "registered root $Root" }
miktex fndb refresh

# kpsewhich searches "." before the roots, so check from outside the clone,
# otherwise this would find the local copies and always look like success.
Push-Location $HOME
"kpsewhich $name.sty -> " + (kpsewhich "$name.sty")
"kpsewhich $name.bib -> " + (kpsewhich "$name.bib")
Pop-Location
