$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
Add-Type -Path "$PSScriptRoot\VerifyMotion.cs"
[VerifyMotion]::Run("$root\build\motion-banks.bin","$root\build\8m\motion-banks.bin",1,0)
[VerifyMotion]::Run("$root\build\motion-banks.bin","$root\build\2m\motion-banks.bin",2,16)
