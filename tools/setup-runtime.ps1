param(
 [Parameter(Mandatory=$true)][string]$EmulatorRoot,
 [string]$SystemROMs,
 [string]$CBIOS
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
foreach($name in @('MOTIONGT.xml','MOTIONCB.xml')){
 if(!(Test-Path -LiteralPath (Join-Path "$root\tools\machines" $name))){throw "Missing machine definition $name; restore tools/machines from the repository."}
}
$source=(Resolve-Path -LiteralPath $EmulatorRoot).Path
if(!(Test-Path "$source\openmsx.exe") -or !(Test-Path "$source\share")){
 throw 'EmulatorRoot must contain openmsx.exe and share, with V9968 + geo3d + ASCII16-X support.'
}
if(!(Test-Path "$root\emulator")){Copy-Item -LiteralPath $source -Destination "$root\emulator" -Recurse}
New-Item -ItemType Directory -Force "$root\runtime\share\machines","$root\runtime\share\systemroms" | Out-Null
Copy-Item "$root\tools\machines\MOTION*.xml" "$root\runtime\share\machines" -Force
if($SystemROMs){
 foreach($name in @('fs-a1gt_firmware.rom','fs-a1gt_kanjifont.rom')){
  $file=Join-Path $SystemROMs $name
  if(!(Test-Path -LiteralPath $file)){throw "Missing required BIOS file: $name"}
  Copy-Item -LiteralPath $file -Destination "$root\runtime\share\systemroms" -Force
 }
}
if($CBIOS){
 foreach($name in @('cbios_main_msx2+_jp.rom','cbios_logo_msx2+.rom','cbios_sub.rom','cbios_music.rom')){
  $file=Join-Path $CBIOS $name
  if(!(Test-Path -LiteralPath $file)){throw "Missing C-BIOS file: $name"}
  Copy-Item -LiteralPath $file -Destination "$root\runtime\share\machines" -Force
 }
}
Write-Output 'Runtime configured. Supply BIOS files for the selected machine before launching. Runtime and BIOS are excluded from Git.'