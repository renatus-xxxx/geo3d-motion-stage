$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Add-Type -Path "$PSScriptRoot\BvhBake.cs"
[BvhBake]::Run("$root\assets", "$root\build")
Get-Content "$root\build\bake-report.txt"
