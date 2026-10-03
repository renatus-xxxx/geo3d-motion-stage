param([ValidateSet('CB','GT')][string]$Machine='GT',[switch]$Effects,[switch]$Single,[switch]$Reset,[switch]$AllEffects,[switch]$AutoMapper,[switch]$EndPaused)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$map=Get-Content "$root\build\STAGE.map" -Raw
$out="$root\output\test-$Machine$(if($Effects){'-effects'})$(if($Single){'-single'})$(if($Reset){'-reset'})$(if($AllEffects){'-all-effects'})$(if($AutoMapper){'-auto-mapper'})$(if($EndPaused){'-end-paused'})"
New-Item -ItemType Directory -Force $out | Out-Null
$symbols=@{}
foreach($name in @('stage_ready','displayed_frames','motion_frame','selected_bank','video_error','platform_r800','camera_yaw','camera_pitch','camera_zoom','trails','reflection','paused','actor_mode','vblank_ticks','matrix','focus','distance','pose','music_ticks','music_enabled','white_level','playback_ticks')){
 $match=[regex]::Match($map,'(?m)^_'+$name+'\s*=\s*\$([0-9a-fA-F]+)')
 if(!$match.Success){throw "Missing symbol $name"}
 $symbols[$name]=[Convert]::ToInt32($match.Groups[1].Value,16)
}
$tcl=@'
set save_settings_on_exit false
set throttle false
set sound_driver null
set maxframeskip 0
set minframeskip 0
set vsync off
set pause_on_lost_focus false
set out {@OUT@}
set log [open "$out/events.txt" w]
set samples 0
set max_bank 0
set max_pose 0
set loops 0
set previous_pose 0
set first_time 0
set first_count 0
set fit_checks 0
set resetting 0
set romfile [open {@ROOT@/build/MOTION.rom} rb]
set rom [read $romfile]
close $romfile
proc byte {a} {debug read memory $a}
proc word {a} {expr {[byte $a]+256*[byte [expr {$a+1}]]}}
proc note {s} {puts $::log $s;flush $::log}
proc signed {a} {set n [word $a];expr {$n>=32768?$n-65536:$n}}
proc check_fit {} {
 if {$::resetting} {return}
 if {[word @stage_ready@]!=19795} {return}
 set nv [expr {[byte @actor_mode@]?60:180}]
 set actor [expr {[byte @actor_mode@]?[byte @actor_mode@]-1:0}]
 set ptr [expr {[word @pose@]+$actor*360}]
 set bank [word @selected_bank@]
 if {[debug read_block memory 16384 16] ne [string range $::rom [expr {$bank*16384}] [expr {$bank*16384+15}]]} {
  note "FAIL mapped ROM bank=$bank";exit
 }
 set distance [signed @distance@]
 set reflection [byte @reflection@]
 set matrix {}
 for {set i 0} {$i<9} {incr i} {lappend matrix [signed [expr {@matrix@+2*$i}]]}
 set focus {}
 for {set i 0} {$i<3} {incr i} {lappend focus [signed [expr {@focus@+2*$i}]]}
 for {set vertex 0} {$vertex<$nv} {incr vertex} {
  set x [signed [expr {$ptr+6*$vertex}]]
  set y [signed [expr {$ptr+6*$vertex+2}]]
  set z [signed [expr {$ptr+6*$vertex+4}]]
  for {set mirror 0} {$mirror<=$reflection} {incr mirror} {
   set yy [expr {$mirror?2*@FLOOR@-$y:$y}]
   set input [list $x $yy $z]
   set result {}
   for {set row 0} {$row<3} {incr row} {
    set total 0
    set shift 0
    for {set col 0} {$col<3} {incr col} {
     set m [lindex $matrix [expr {$row*3+$col}]]
     incr total [expr {$m*[lindex $input $col]}]
     incr shift [expr {($m*[lindex $focus $col])>>14}]
    }
    lappend result [expr {($total>>14)-$shift+($row==2?$distance:0)}]
   }
   set depth [lindex $result 2]
   set sx [expr {256+[lindex $result 0]*320/$depth}]
   set sy [expr {212-[lindex $result 1]*320/$depth}]
   if {$depth<48 || $sx<0 || $sx>=512 || $sy<0 || $sy>=424} {
    note "FAIL camera vertex=$vertex mirror=$mirror projected=$sx,$sy,$depth";exit
   }
  }
 }
 incr ::fit_checks
}
proc on_frame {} {if {[word @displayed_frames@]%15==0} {check_fit}}
debug set_watchpoint write_mem [expr {@displayed_frames@+1}] {} on_frame
proc sample {} {
 set count [word @displayed_frames@]
 set pose [word @motion_frame@]
 set bank [word @selected_bank@]
 if {!$::resetting && [word @stage_ready@]==19795 && $count>0} {
  if {$::first_time==0} {set ::first_time [machine_info time];set ::first_count $count}
  set error [byte @video_error@]
  if {$error} {note "FAIL video_error=$error";exit}
  if {[get_active_cpu] ne "@CPU@"} {note "FAIL CPU mode";exit}
  if {$pose<$::previous_pose && $::previous_pose>1300} {incr ::loops}
  set ::previous_pose $pose
  if {$bank>$::max_bank} {set ::max_bank $bank}
  if {$pose>$::max_pose} {set ::max_pose $pose}
  note "t=[machine_info time] frames=$count pose=$pose bank=$bank cpu=[get_active_cpu] r800=[byte @platform_r800@] clock=[word @vblank_ticks@]"
 }
 after time 1 sample
}
proc shot {name} {screenshot -raw "$::out/$name.png"}
after time 1 sample
after time 8 {shot early}
after time 35 {shot middle}
after time 65 {shot late}

after time 48 {keymatrixdown 4 4}
after time 48.5 {keymatrixup 4 4}
after time 50 {set muted_clock [word @music_ticks@]}
after time 52 {
 note "music_muted=[byte @music_enabled@] ticks_before=$muted_clock ticks_after=[word @music_ticks@]"
 if {[byte @music_enabled@] != 0 || $muted_clock != [word @music_ticks@]} {note "FAIL music mute"}
 keymatrixdown 4 4
}
after time 52.5 {keymatrixup 4 4}
after time 54 {
 note "music_enabled=[byte @music_enabled@] ticks=[word @music_ticks@]"
 if {[byte @music_enabled@] != 1 || [word @music_ticks@] <= $muted_clock} {note "FAIL music resume"}
}
after time 88 {
 set fps [expr {([word @displayed_frames@]-$::first_count)/([machine_info time]-$::first_time)}]
 note "RESULT frames=[word @displayed_frames@] max_bank=$::max_bank max_pose=$::max_pose loops=$::loops average_fps=$fps fit_checks=$::fit_checks"
 shot final
 close $::log
 exit
}
'@
if(!$Effects -and !$Reset -and !$EndPaused){
 $tcl += @'

after time 78 {
 note "END white=[byte @white_level@] frame=[word @motion_frame@] ticks=[word @playback_ticks@]"
 if {[byte @white_level@]!=31 || [word @motion_frame@]!=1409} {note "FAIL ending whiteout"}
 screenshot -raw {@OUT@/ending.png}
}
after time 80 {keymatrixdown 7 4}
after time 80.5 {keymatrixup 7 4}
after time 82 {
 note "END_RESTART white=[byte @white_level@] frame=[word @motion_frame@]"
 if {[byte @white_level@]!=0 || [word @motion_frame@]>100} {note "FAIL ending restart"}
}
'@
}
if($Single){$tcl+="`nafter time 6 {keymatrixdown 3 1}`nafter time 6.4 {keymatrixup 3 1}`n"}
if($AllEffects){$tcl+="`nafter time 6 {keymatrixdown 5 2;keymatrixdown 4 128}`nafter time 6.4 {keymatrixup 5 2;keymatrixup 4 128}`nafter time 8 {note `"effects trails=[byte @trails@] reflection=[byte @reflection@] actor_mode=[byte @actor_mode@]`"}`n"}
if($Reset){$tcl+=@'

after time 76 {set resetting 1;set reset_previous_count [word @displayed_frames@];note RESET_REQUEST;reset}
after time 84 {
 if {[word @stage_ready@]!=19795 || [word @displayed_frames@]>=$reset_previous_count || [get_active_cpu] ne "@CPU@"} {note "FAIL reset boot";exit}
 set resetting 0
 shot reset
 note "RESET_BOOT ready=[word @stage_ready@] frames=[word @displayed_frames@] cpu=[get_active_cpu]"
}
'@}
if($Effects){
 $tcl += @'

after time 10 {keymatrixdown 5 2}
after time 10.2 {keymatrixup 5 2}
after time 12 {keymatrixdown 4 128}
after time 12.2 {keymatrixup 4 128}
after time 17 {shot effects;note "effects trails=[byte @trails@] reflection=[byte @reflection@]"}
after time 18 {keymatrixdown 8 128}
after time 19 {keymatrixup 8 128;shot rotated;note "yaw=[byte @camera_yaw@]"}
after time 20 {keymatrixdown 8 1}
after time 20.2 {keymatrixup 8 1}
after time 21 {set paused_pose [word @motion_frame@]}
after time 23 {note "pause=[byte @paused@] pose_before=$paused_pose pose_after=[word @motion_frame@]";keymatrixdown 8 1}
after time 23.2 {keymatrixup 8 1}
after time 25 {keymatrixdown 3 1}
after time 25.2 {keymatrixup 3 1}
after time 28 {shot single;note "actor_mode=[byte @actor_mode@]"}
after time 30 {keymatrixdown 6 1;keymatrixdown 8 64}
after time 31 {keymatrixup 8 64;keymatrixup 6 1;note "zoom=[byte @camera_zoom@]"}
after time 32 {keymatrixdown 8 32}
after time 33 {keymatrixup 8 32;note "pitch=[byte @camera_pitch@]";shot pitched}
after time 34 {keymatrixdown 7 4}
after time 34.4 {keymatrixup 7 4}
after time 36 {note "restart pose=[word @motion_frame@] yaw=[byte @camera_yaw@] zoom=[byte @camera_zoom@]";shot restarted}
'@
}
if($EndPaused){$tcl+=@'

after time 12 {keymatrixdown 8 1}
after time 12.4 {keymatrixup 8 1}
after time 13 {
 if {[byte @paused@]!=1} {note "FAIL pause before E";exit}
 note "END_PAUSED paused=1"
}
after time 14 {keymatrixdown 3 4;keymatrixdown 8 1}
after time 14.4 {keymatrixup 3 4;keymatrixup 8 1}
after time 16 {
 note "END_PAUSED_COMPLETE paused=[byte @paused@] white=[byte @white_level@] frame=[word @motion_frame@]"
 if {[byte @paused@]!=0 || [byte @white_level@]!=31 || [word @motion_frame@]!=1409} {note "FAIL paused E ending";exit}
}
after time 17 {keymatrixdown 7 4}
after time 17.4 {keymatrixup 7 4}
after time 19 {
 if {[byte @white_level@]!=0 || [word @motion_frame@]>100} {note "FAIL paused E restart";exit}
 note END_PAUSED_RESTART
}
'@}
$floor=[regex]::Match((Get-Content "$root\build\motion_data.h" -Raw),'FLOOR_Y (-?\d+)').Groups[1].Value
$tcl=$tcl.Replace('@FLOOR@',$floor)
$tcl=$tcl.Replace('@OUT@',$out.Replace('\','/'))
$tcl=$tcl.Replace('@ROOT@',$root.Replace('\','/')).Replace('@CPU@',$(if($Machine -eq 'GT'){'r800'}else{'z80'}))
foreach($key in $symbols.Keys){$tcl=$tcl.Replace("@$key@",[string]$symbols[$key])}
$path="$out/test.tcl"
[IO.File]::WriteAllText($path,$tcl)
$env:OPENMSX_HOME="$out\home"
New-Item -ItemType Directory -Force $env:OPENMSX_HOME | Out-Null
$env:OPENMSX_USER_DATA="$root\runtime\share"
$env:OPENMSX_SYSTEM_DATA="$root\emulator\share"
$taskArguments="-machine MOTION$Machine -ext geo3d -carta `"$root\build\MOTION.rom`" -romtype ASCII16-X -script `"$path`""
if($AutoMapper){$taskArguments=$taskArguments.Replace(' -romtype ASCII16-X','')}
$process=Start-Process "$root\emulator\openmsx.exe" -ArgumentList $taskArguments -WindowStyle Hidden -RedirectStandardError "$out/stderr.txt" -RedirectStandardOutput "$out/stdout.txt" -PassThru -Wait
Get-Content "$out/stderr.txt"
if($process.ExitCode -ne 0){throw "Emulator exit code $($process.ExitCode)"}
Get-Content "$out/events.txt" -Tail 4
$events=Get-Content "$out/events.txt"
if($events -match '^FAIL '){throw 'Runtime check failed'}
if(!($events -match '^RESULT ')){throw 'No completion marker'}
$result=[regex]::Match(($events -join "`n"),'RESULT .*max_bank=(\d+)')
if(!$result.Success -or [int]$result.Groups[1].Value -le 255){throw 'Upper ASCII16-X banks not exercised'}
if(!($events -match 'fit_checks=[1-9]')){throw 'Camera checks did not run'}
if($Effects){
 if(!($events -match 'effects trails=1 reflection=1')){throw 'Effects keys were not handled'}
 $pause=[regex]::Match(($events -join "`n"),'pause=1 pose_before=(\d+) pose_after=(\d+)')
 if(!$pause.Success -or $pause.Groups[1].Value -ne $pause.Groups[2].Value){throw 'Pause did not hold the pose'}
 if(!($events -match 'actor_mode=1')){throw 'Single character selection failed'}
 if(!($events -match 'restart pose=\d+ yaw=0 zoom=100')){throw 'Esc restart failed'}
}
if($Reset -and !($events -match 'RESET_BOOT ready=19795')){throw 'Reset did not cold boot again'}
if($AllEffects -and !($events -match 'effects trails=1 reflection=1 actor_mode=0')){throw 'All effects were not active'}
if($EndPaused -and !($events -match 'END_PAUSED_COMPLETE paused=0 white=31 frame=1409')){throw 'Paused end regression did not complete'}
$pass="PASS $Machine effects=$Effects single=$Single reset=$Reset allEffects=$AllEffects"
Add-Content -LiteralPath "$out/events.txt" -Value $pass -Encoding ascii
Write-Output $pass
