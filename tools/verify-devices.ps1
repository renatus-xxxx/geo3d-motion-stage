param([ValidateSet('missing-vdp','missing-geo','external-missing-geo','lost-irq','lost-irq-hold')][string]$Case='missing-vdp',[string]$RuntimeRoot='')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!$RuntimeRoot){$RuntimeRoot=$root}
$out="$root/output/device-$Case";New-Item -ItemType Directory -Force "$out/home","$out/share/machines","$out/share/systemroms" | Out-Null
$config=Get-Content "$root/tools/machines/MOTIONCB.xml" -Raw
if($Case -eq 'missing-vdp' -or $Case -eq 'external-missing-geo'){
 $config=$config.Replace('<version>V9968</version>','<version>V9958</version>').Replace('<vram>256</vram>','<vram>128</vram>')
}
[IO.File]::WriteAllText("$out/share/machines/DEVICE.xml",$config)
foreach($name in @('cbios_main_msx2+_jp.rom','cbios_logo_msx2+.rom','cbios_sub.rom','cbios_music.rom')) {
 $file="$RuntimeRoot/runtime/share/machines/$name";if(!(Test-Path $file)){throw "Missing test BIOS $name"}
 Copy-Item -LiteralPath $file -Destination "$out/share/machines" -Force
}
$expected=if($Case -eq 'missing-vdp'){2}elseif($Case -like 'lost-irq*'){4}else{5}
$port=if($Case -eq 'external-missing-geo'){137}else{153}
$tcl=@'
set renderer none
set throttle false
set save_settings_on_exit false
set sound_driver null
set log [open {@OUT@/events.txt} w]
set injected 0
proc byte {a} {debug read memory $a}
proc word {a} {expr {[byte $a]+256*[byte [expr {$a+1}]]}}
proc fail {s} {puts $::log "FAIL $s";close $::log;exit}
proc sample {} {
 if {@IRQ@ && !$::injected && [word @stage_ready@]==19795 && (@HOLD@==0 || [byte @demo_wait@]==1)} {
  # Deliberate emulated hardware fault, never a game-state edit.
  debug write {VDP regs} 1 64
  set ::injected 1
  puts $::log "FAULT VBlank interrupt disabled"
 }
 if {[byte @video_error@]==@EXPECTED@} {
  if {[byte @video_control_port@]!=@PORT@} {fail "selected port"}
  set ::stopped [word @vblank_ticks@]
  after time 0.5 {
   if {[word @vblank_ticks@]!=$::stopped} {fail "clock still advances"}
   puts $::log "PASS expected_error=@EXPECTED@ selected_port=@PORT@ clock_stopped";close $::log;exit
  }
  return
 }
 after time 0.1 sample
}
after time 0.1 sample
after time 100 {fail "device failure did not stop safely"}
'@
$map=Get-Content "$root/build/2m/STAGE.map" -Raw
foreach($name in @('stage_ready','demo_wait','video_error','video_control_port','vblank_ticks')) {
 $m=[regex]::Match($map,'(?m)^_'+$name+'\s*=\s*\$([0-9A-Fa-f]+)');if(!$m.Success){throw "Missing symbol $name"}
 $tcl=$tcl.Replace("@$name@",[string][Convert]::ToInt32($m.Groups[1].Value,16))
}
$tcl=$tcl.Replace('@OUT@',$out.Replace('\','/')).Replace('@EXPECTED@',"$expected").Replace('@PORT@',"$port").Replace('@IRQ@',$(if($Case -like 'lost-irq*'){'1'}else{'0'})).Replace('@HOLD@',$(if($Case -eq 'lost-irq-hold'){'1'}else{'0'}))
[IO.File]::WriteAllText("$out/test.tcl",$tcl)
$env:OPENMSX_HOME="$out/home";$env:OPENMSX_USER_DATA="$out/share";$env:OPENMSX_SYSTEM_DATA="$RuntimeRoot/emulator/share"
$extension=if($Case -like 'lost-irq*'){'-ext geo3d'}elseif($Case -eq 'external-missing-geo'){'-ext HRA_V9968'}else{''}
$process=Start-Process "$RuntimeRoot/emulator/openmsx.exe" -ArgumentList "-machine DEVICE $extension -carta `"$root/build/MOTION2.ROM`" -romtype ASCII16 -script `"$out/test.tcl`"" -WindowStyle Hidden -PassThru -Wait -RedirectStandardError "$out/stderr.txt" -RedirectStandardOutput "$out/stdout.txt"
if($process.ExitCode -or !(Select-String -Path "$out/events.txt" -Pattern '^PASS ') -or (Select-String -Path "$out/events.txt" -Pattern '^FAIL ')){throw "Device test failed: $out"}
Write-Output "PASS $Case"
