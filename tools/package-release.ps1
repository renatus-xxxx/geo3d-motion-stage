param()
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force "$root\dist" | Out-Null
foreach($name in @('MOTION.rom','MOTION-native.rom')){
 $source="$root\build\$name"
 if(!(Test-Path $source)){throw "Build $name first"}
 $bytes=[IO.File]::ReadAllBytes($source)
 if($bytes.Length -ne 8388608 -or [Text.Encoding]::ASCII.GetString($bytes,16,8) -ne 'ASCII16X'){
  throw "Invalid ASCII16-X ROM: $name"
 }
 Copy-Item -LiteralPath $source -Destination "$root\dist\$name" -Force
}
if(!(Test-Path "$root\output\motion-stage-demo.mp4")){throw 'Create the demo video first'}
Copy-Item -LiteralPath "$root\output\motion-stage-demo.mp4" -Destination "$root\dist\motion-stage-demo.mp4" -Force
$credit='Perfume global site project #001'
if(!([IO.File]::ReadAllText("$root\dist\NOTICE.txt").Contains("BVH motion data: $credit"))){throw 'NOTICE credit differs from official project attribution'}
$files=@()
$checksums=@()
foreach($name in @('MOTION.rom','MOTION-native.rom','motion-stage-demo.mp4','NOTICE.txt')){
 $path="$root\dist\$name"
 $sha=[Security.Cryptography.SHA256]::Create()
 try {$hash=[BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($path))).Replace('-','').ToLowerInvariant()}
 finally {$sha.Dispose()}
 $files += [ordered]@{file=$name;bytes=(Get-Item $path).Length;sha256=$hash}
 $checksums += "$hash  $name"
}
$manifest=[ordered]@{
 project='geo3d-motion-stage'
 rom_mapper='ASCII16-X'
 display='SCREEN 7 FIL, 512x424, 16 colors'
 minimum_ram_bytes=65536
 vram_bytes=262144
 required_extension='V9968 + geo3d'
 legacy_rom='MOTION.rom'
 native_rom='MOTION-native.rom'
 validation=[ordered]@{legacy='R800 and Z80 emulator';native='current ROM: build only; earlier native ROM: blueMSX+ 2090cd2 visual boot/playback/white-ending check with field artifacts; controls/audio/CPU readback/reset and hardware untested'}
 bvh_source='https://perfume-global.com/web/2012/03/perfume-global-site-project-001/'
 bvh_credit='Perfume global site project #001'
 bvh_use_basis='fan-created derivative demo following the official project description'
 bvh_official_project='https://perfume-global.com/web/2012/03/perfume-global-site-project-001/'
 files=$files
}
[IO.File]::WriteAllText("$root\dist\manifest.json",($manifest | ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText("$root\dist\SHA256SUMS.txt",(($checksums -join "`n")+"`n"),[Text.Encoding]::ASCII)
Write-Output 'Distribution packaged and checksums updated.'
