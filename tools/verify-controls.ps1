param([ValidateSet('8m','2m')][string]$Profile='8m',[ValidateSet('GT','CB')][string]$Machine='GT',[string]$RuntimeRoot='',[switch]$AutoMapper)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent;if(!$RuntimeRoot){$RuntimeRoot=$root}
$out="$root\output\controls-$Profile-$Machine$(if($AutoMapper){'-auto'})";New-Item -ItemType Directory -Force $out,"$out\home" | Out-Null
$map=Get-Content "$root\build\$Profile\STAGE.map" -Raw
$name=if($Profile -eq '2m'){'MOTION2.ROM'}else{'MOTION8.ROM'}
$tcl=@'
set renderer none
set save_settings_on_exit false
set throttle false
set sound_driver null
set pause_on_lost_focus false
set out {@OUT@};set log [open "$out/events.txt" w]
set begun 0
proc byte {a} {debug read memory $a}
proc word {a} {expr {[byte $a]+256*[byte [expr {$a+1}]]}}
proc note {s} {puts $::log $s;flush $::log}
proc check {ok message} {if {!$ok} {note "FAIL $message";close $::log;exit};note "OK $message"}
proc key {row bit} {keymatrixdown $row $bit;after time 0.4 [list keymatrixup $row $bit]}
proc begin {} {
 if {$::begun || [word @stage_ready@]!=19795 || [byte @demo_wait@]!=0} {return}
 set ::begun 1
 after time 2 {key 5 2}
 after time 3 {check [expr {![byte @demo_active@] && [byte @trails@]}] "T enters manual";key 5 2}
 after time 4 {key 4 128}
 after time 5 {key 3 1}
 after time 6 {key 4 4}
 after time 7 {check [expr {![byte @music_enabled@] && [byte @reflection@] && [byte @actor_mode@]==1}] "R C mute";set ::muted_music [word @music_ticks@]}
 after time 8 {check [expr {[word @music_ticks@]>$::muted_music}] "muted sequencer advances";key 4 4}
 after time 9 {key 8 1}
 after time 10 {check [expr {[byte @paused@]}] "pause";set ::paused_time [word @playback_ticks@]}
 after time 12 {check [expr {[word @playback_ticks@]==$::paused_time}] "paused motion clock";key 8 1}
 after time 14 {key 3 4;key 8 1}
 after time 16 {check [expr {![byte @paused@] && [byte @white_level@]==31}] "E wins simultaneous Space and fades";key 7 4}
 after time 19 {check [expr {![byte @demo_active@] && [byte @white_level@]==0 && ![byte @trails@] && ![byte @reflection@] && ![byte @actor_mode@]}] "Esc resets manual scene";key 3 2}
 after time 22 {check [expr {[byte @demo_active@] && [word @playback_ticks@]<240}] "D returns to demo";key 4 4}
 after time 23 {key 7 4}
 after time 26 {check [expr {[byte @demo_active@] && ![byte @music_enabled@] && [byte @white_level@]==0 && [word @playback_ticks@]<240}] "Esc restarts demo and retains mute";reset}
 after time 37 {
  check [expr {[word @stage_ready@]==19795 && ![byte @video_error@] && [get_active_cpu] eq "@CPU@" && [byte @demo_active@] && [byte @music_enabled@]}] "reset cold boots ROM"
  note PASS;close $::log;exit
 }
}
debug set_watchpoint write_mem @demo_wait@ {} begin
after time 20 {if {!$::begun} {note "FAIL boot";exit}}
'@
foreach($s in @('stage_ready','demo_wait','demo_active','trails','reflection','actor_mode','music_enabled','music_ticks','paused','playback_ticks','white_level','video_error')){$v=[regex]::Match($map,'(?m)^_'+$s+'\s*=\s*\$([0-9A-Fa-f]+)');if(!$v.Success){throw "Missing symbol $s"};$tcl=$tcl.Replace("@$s@",[string][Convert]::ToInt32($v.Groups[1].Value,16))}
$tcl=$tcl.Replace('@OUT@',$out.Replace('\','/')).Replace('@CPU@',$(if($Machine -eq 'GT'){'r800'}else{'z80'}));[IO.File]::WriteAllText("$out/run.tcl",$tcl)
$env:OPENMSX_HOME="$out\home";$env:OPENMSX_USER_DATA="$RuntimeRoot\runtime\share";$env:OPENMSX_SYSTEM_DATA="$RuntimeRoot\emulator\share"
$mapper=if($AutoMapper){''}else{if($Profile -eq '2m'){'-romtype ASCII16'}else{'-romtype ASCII16-X'}}
$taskArguments="-machine MOTION$Machine -ext geo3d -carta `"$root\build\$name`" $mapper -script `"$out\run.tcl`""
$p=Start-Process "$RuntimeRoot\emulator\openmsx.exe" -ArgumentList $taskArguments -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardError "$out/stderr.txt" -RedirectStandardOutput "$out/stdout.txt"
Write-Output "START controls $out PID=$($p.Id)"
