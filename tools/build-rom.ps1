param([ValidateSet('8m','2m','all')][string]$Profile='all',[switch]$Native,[switch]$ScanBounds,[switch]$Rebake)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
Set-Location $root
if(!$env:Z88DK){$env:Z88DK='C:\z88dk'}
$env:PATH="$env:Z88DK\bin;$env:PATH";$env:ZCCCFG="$env:Z88DK\lib\config"
$profiles=if($Profile -eq 'all'){@('8m','2m')}else{@($Profile)}
New-Item -ItemType Directory -Force "$root\build" | Out-Null
& tools/get-bvh.ps1
if($Rebake -or !(Test-Path "$root\build\motion-banks.bin")) {
 & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\tools\bake.ps1"
 if($LASTEXITCODE){throw 'BVH bake failed'}
}
Add-Type -Path "$root\tools\CompactMotion.cs"
foreach($p in $profiles) {
 $folder=if($ScanBounds){"$p-scan"}else{$p}
 $out="$root\build\$folder";New-Item -ItemType Directory -Force $out | Out-Null
 [CompactMotion]::Run("$root\build\motion-banks.bin",$out,$(if($p -eq '2m'){2}else{1}),$(if($p -eq '2m'){16}else{0}))
 $suffix=if($Native){'-native'}else{''}
 $flags=@();if($Native){$flags+='-DV9968_NATIVE_FIL'};if($p -eq '2m'){$flags+='-DROM_ASCII16'};if($ScanBounds){$flags+='-DMOTION_SCAN_BOUNDS'}
 & "$env:Z88DK\bin\zcc.exe" +msx -subtype=bin -zorg=33792 -compiler=sdcc -SO2 -pragma-define:REGISTER_SP=62208 -pragma-define:CRT_ENABLE_EIDI=0 @flags -Isrc "-Ibuild/$folder" src/main.c src/demo.c src/video.c src/scene.c src/trig.c src/platform.c src/music.c -o "build/$folder/STAGE$suffix.bin" -m *> "$out/build$suffix.log"
 if($LASTEXITCODE){throw "Compile failed: $out/build$suffix.log"}
 & tools/pack.ps1 -Profile $p -Work $out -Layout -Native:$Native
 $boot=(Get-Content src/boot.asm -Raw).Replace('build/rom_layout.inc',"build/$folder/rom_layout$suffix.inc")
 if($p -eq '2m'){$boot=$boot.Replace('ASCII16X','ASC16ROM')}
 [IO.File]::WriteAllText("$out/boot$suffix.asm",$boot)
 & "$env:Z88DK\bin\z88dk-z80asm.exe" -b -m -l "-obuild/$folder/BOOT$suffix.bin" "build/$folder/boot$suffix.asm" *> "$out/boot$suffix.log"
 if($LASTEXITCODE){throw "Boot build failed: $out/boot$suffix.log"}
 & tools/pack.ps1 -Profile $p -Work $out -Destination $(if($ScanBounds){$out}else{"$root\build"}) -Native:$Native
}
