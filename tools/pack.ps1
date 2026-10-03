param([switch]$Layout,[switch]$Native)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$suffix=if($Native){"-native"}else{""}
$game=[IO.File]::ReadAllBytes("$root\build\STAGE$suffix.bin")
if($game.Length -gt 16384){throw 'RAM payload exceeds bank 1'}
$map=Get-Content "$root\build\STAGE$suffix.map" -Raw
$bss=[regex]::Match($map,'(?m)^__BSS_END_tail\s*=\s*\$([0-9A-Fa-f]+)')
if(!$bss.Success -or [Convert]::ToInt32($bss.Groups[1].Value,16) -gt 0xE000){throw 'RAM/BSS overlaps loader at E200'}
if($Layout){[IO.File]::WriteAllText("$root\build\rom_layout$suffix.inc", "defc GAME_SIZE = $($game.Length)`r`n");exit}
$boot=[IO.File]::ReadAllBytes("$root\build\BOOT$suffix.bin")
if($boot.Length -lt 24 -or [Text.Encoding]::ASCII.GetString($boot,16,8) -ne 'ASCII16X'){throw 'Missing ASCII16-X identification'}
$data=[IO.File]::ReadAllBytes("$root\build\motion-banks.bin")
if($boot.Length -gt 16384 -or $data.Length+32768 -gt 8388608){throw 'ROM layout overflow'}
$rom=New-Object byte[] 8388608
$padding=New-Object byte[] 16384
for($i=0;$i -lt $padding.Length;$i++){$padding[$i]=255}
for($offset=0;$offset -lt $rom.Length;$offset+=16384){[Array]::Copy($padding,0,$rom,$offset,16384)}
[Array]::Copy($boot,0,$rom,0,$boot.Length)
[Array]::Copy($game,0,$rom,16384,$game.Length)
[Array]::Copy($data,0,$rom,32768,$data.Length)
[IO.File]::WriteAllBytes("$root\build\MOTION$suffix.rom",$rom)
$sha=[Security.Cryptography.SHA256]::Create()
$hash=[BitConverter]::ToString($sha.ComputeHash($rom)).Replace('-','').ToLowerInvariant()
[IO.File]::WriteAllText("$root\build\rom-sha256$suffix.txt",$hash)
Write-Output "MOTION$suffix.rom: 8388608 bytes; SHA256 $hash"
