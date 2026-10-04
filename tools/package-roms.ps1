$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force "$root\dist" | Out-Null
$roms=@()
foreach($p in @('8m','2m')) {
 foreach($native in @($false,$true)) {
  $name=if($p -eq '8m'){if($native){'MOT8N.ROM'}else{'MOTION8.ROM'}}else{if($native){'MOT2N.ROM'}else{'MOTION2.ROM'}}
  $size=if($p -eq '8m'){8388608}else{2097152}
  $bytes=[IO.File]::ReadAllBytes("$root\build\$name")
  $identity=if($p -eq '8m'){'ASCII16X'}else{'ASC16ROM'}
  if($bytes.Length -ne $size -or [Text.Encoding]::ASCII.GetString($bytes,16,8) -ne $identity){throw "Invalid ROM $name"}
  Copy-Item "$root\build\$name" "$root\dist\$name" -Force
  $roms += [ordered]@{file=$name;bytes=$size;mapper=$(if($p -eq '8m'){'ASCII16-X'}else{'ASCII16'});pose_hz=$(if($p -eq '8m'){20}else{10});normal_bits=16;fil=$(if($native){'R20 bit5'}else{'R21 bit6'});minimum_ram_bytes=65536;vram_bytes=262144}
 }
}
foreach($old in @('MOTION.rom','MOTION-native.rom')){if(Test-Path "$root\dist\$old"){Remove-Item -LiteralPath "$root\dist\$old"}}
Copy-Item "$root\output\motion-stage-demo.mp4" "$root\dist\motion-stage-demo.mp4" -Force
foreach($cpu in @('r800','z80')){Copy-Item "$root\output\report\comparison-$cpu.mp4" "$root\dist\comparison-$cpu.mp4" -Force}
if(![IO.File]::ReadAllText("$root\dist\NOTICE.txt").Contains('BVH motion data: Perfume global site project #001')){throw 'Missing official BVH attribution'}
$files=@();$sums=@()
foreach($name in @('MOTION8.ROM','MOT8N.ROM','MOTION2.ROM','MOT2N.ROM','motion-stage-demo.mp4','comparison-r800.mp4','comparison-z80.mp4','NOTICE.txt')) {
 $path="$root\dist\$name";$hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
 $files += [ordered]@{file=$name;bytes=(Get-Item -LiteralPath $path).Length;sha256=$hash};$sums+="$hash  $name"
}
$manifest=[ordered]@{project='geo3d-motion-stage';roms=$roms;display='SCREEN 7 FIL, 512x424, 16 colors';video_hz=60;required_extension='V9968 + geo3d';default_mode='automatic looping demo';bvh_source='https://perfume-global.com/web/2012/03/perfume-global-site-project-001/';bvh_credit='Perfume global site project #001';bvh_use_basis='fan-created derivative demo following the official project description';validation=[ordered]@{openmsx='See VERIFICATION.md for current results';native='Build verified; current ROM runtime and physical FPGA unverified';sx2='Standard ASCII16 format; physical SX-2 and loader unverified'};files=$files}
[IO.File]::WriteAllText("$root\dist\manifest.json",($manifest|ConvertTo-Json -Depth 8)+"`n",[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText("$root\dist\SHA256SUMS.txt",($sums -join "`n")+"`n",[Text.Encoding]::ASCII)
Write-Output 'Packaged four 8.3 ROMs and three videos.'
