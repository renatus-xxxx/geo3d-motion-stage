param([ValidateSet('8m','2m')][string]$Profile='8m',[ValidateSet('GT','CB')][string]$Machine='GT',[int]$Seconds=160,[switch]$Realtime,[switch]$Capture,[switch]$Background,[switch]$Fit,[switch]$ManualCamera,[switch]$Headless,[string]$RuntimeRoot='',[string]$Label='')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!$RuntimeRoot){$RuntimeRoot=$root}
$name=if($Profile -eq '2m'){'MOTION2.ROM'}else{'MOTION8.ROM'}
$mapper=if($Profile -eq '2m'){'ASCII16'}else{'ASCII16-X'}
$out="$root\output\verify-$Profile-$Machine$Label";New-Item -ItemType Directory -Force $out,"$out\home" | Out-Null
Copy-Item "$root\build\$name" "$out\$name" -Force
$romPath="$out\$name"
$map=Get-Content "$root\build\$Profile\STAGE.map" -Raw
$header=Get-Content "$root\build\$Profile\motion_data.h" -Raw
$stored=[int][regex]::Match($header,'#define STORED_FRAMES (\d+)').Groups[1].Value
$motionFrames=[int][regex]::Match($header,'#define MOTION_FRAMES (\d+)').Groups[1].Value
$perBank=[int][regex]::Match($header,'#define POSES_PER_BANK (\d+)').Groups[1].Value
$maxBank=2+[Math]::Floor(($stored-1)/$perBank)
$minBank=if($Profile -eq '8m'){[Math]::Min(256,$maxBank)}else{[Math]::Max(2,$maxBank-1)}
$tcl=@'
set save_settings_on_exit false
set throttle @THROTTLE@
set sound_driver null
set minframeskip 0
set maxframeskip 0
set vsync off
set pause_on_lost_focus false
set out {@OUT@}
set log [open "$out/events.txt" w]
set started 0
set lastclock 0
set lastframes 0
set wraps 0
set framewraps 0
set whites 0
set lastwhite 0
set loops 0
set maxbank 0
set maxpose 0
proc byte {a} {debug read memory $a}
proc word {a} {expr {[byte $a]+256*[byte [expr {$a+1}]]}}
proc note {s} {puts $::log $s;flush $::log}
proc fail {s} {note "FAIL $s";close $::log;exit}
proc begin {} {
 if {!$::started && [word @stage_ready@]==19795 && [byte @demo_wait@]==0} {
  set ::started 1;set ::epoch [machine_info time];set ::wallstart [clock seconds]
  @RECORD@
  @CAMERAKEYS@
  note "BEGIN t=$::epoch"
  after time @SECONDS@ finish
 }
}
debug set_watchpoint write_mem @demo_wait@ {} begin
proc finish {} {
 if {!$::started || $::loops<1 || $::whites<1 || $::maxpose<@MINPOSE@} {fail "incomplete demo loops=$::loops whites=$::whites maxpose=$::maxpose"}
 if {@SECONDS@>=14400 && ($::loops<190 || $::wraps<12)} {fail "long run too short loops=$::loops wraps=$::wraps"}
 if {$::maxbank<@MINBANK@ || $::maxbank>@MAXBANK@} {fail "bank coverage max=$::maxbank"}
 @FITASSERT@
 @STOP@
 note "PASS seconds=@SECONDS@ loops=$::loops whiteouts=$::whites clock_wraps=$::wraps frame_wraps=$::framewraps max_bank=$::maxbank wall_seconds=[expr {[clock seconds]-$::wallstart}]"
 catch {screenshot -raw "$::out/final.png"}
 close $::log
 exit
}
proc sample {} {
 if {[word @stage_ready@]==19795 && [word @displayed_frames@]>0} {
  if {!$::started} {
   begin
   if {!$::started} {after time 0.5 sample;return}
  }
  if {[byte @video_error@]!=0} {fail "device timeout"}
  if {[get_active_cpu] ne "@CPU@"} {fail "CPU mode"}
  set c [word @vblank_ticks@];set f [word @displayed_frames@]
  if {$c<$::lastclock} {incr ::wraps}
  if {$f<$::lastframes} {incr ::framewraps}
  set ::lastclock $c;set ::lastframes $f
  set l [word @demo_loops@];set w [byte @white_level@]
  if {$w==31 && $::lastwhite!=31} {incr ::whites}
  set ::lastwhite $w;set ::loops $l
  set bank [word @selected_bank@];set pose [word @motion_frame@]
  if {$bank>$::maxbank} {set ::maxbank $bank}
  if {$pose>$::maxpose} {set ::maxpose $pose}
  note "SAMPLE t=[expr {[machine_info time]-$::epoch}] clock=$c frames=$f pose=$pose ticks=[word @playback_ticks@] loop=$l white=$w wait=[byte @demo_wait@] trails=[byte @trails@] reflection=[byte @reflection@] actor=[byte @actor_mode@] music=[word @music_ticks@]"
 }
 after time 0.5 sample
}
after time 0.5 sample
after time 20 {if {!$::started} {fail "cold boot timeout"}}
'@
if($Fit){
 $tcl+=@'

set fit_checks 0
set rf [open {@ROM@} rb];set rom [read $rf];close $rf
proc signed {a} {set n [word $a];expr {$n>=32768?$n-65536:$n}}
proc check_pose {frame mirror} {
 set stored [expr {$frame/@STRIDE@}]
 set base [expr {(2+$stored/@PERBANK@)*16384+($stored%@PERBANK@)*@FRAMEBYTES@}]
 set actor [byte @actor_mode@]
 set start [expr {$actor?($actor-1)*60:0}];set count [expr {$actor?60:180}]
 set distance [signed @distance@]
 for {set vertex $start} {$vertex<$start+$count} {incr vertex} {
  binary scan $::rom @[expr {$base+6*$vertex}]sss x y z
  if {$mirror} {set y [expr {2*@FLOOR@-$y}]}
  set input [list $x $y $z];set result {}
  for {set row 0} {$row<3} {incr row} {
   set total 0;set shift 0
   for {set col 0} {$col<3} {incr col} {
    set m [signed [expr {@matrix@+2*($row*3+$col)}]]
    incr total [expr {$m*[lindex $input $col]}]
    incr shift [expr {($m*[signed [expr {@focus@+2*$col}]])>>14}]
   }
   lappend result [expr {($total>>14)-$shift+($row==2?$distance:0)}]
  }
  set depth [lindex $result 2]
  if {$depth<48} {fail "near plane frame=$frame vertex=$vertex"}
  set sx [expr {256+[lindex $result 0]*320/$depth}];set sy [expr {212-[lindex $result 1]*320/$depth}]
  if {$sx<0 || $sx>=512 || $sy<0 || $sy>=424} {fail "fit frame=$frame vertex=$vertex mirror=$mirror screen=$sx,$sy"}
 }
}
proc check_fit {} {
 if {[word @stage_ready@]!=19795} {return}
 set frame [word @motion_frame@]
 check_pose $frame 0
 if {[byte @reflection@]} {check_pose $frame 1}
 if {[byte @trails@]} {
  if {$frame>=4} {check_pose [expr {$frame-4}] 0}
  if {$frame>=2} {check_pose [expr {$frame-2}] 0}
 }
 # Floor extends outside the viewport, but all corners stay in front of near plane.
 foreach dx {-350 350} {foreach dz {-350 350} {
  set input [list [expr {[signed @focus@]+$dx}] @FLOOR@ [expr {[signed [expr {@focus@+4}]]+$dz}]]
  set total 0;set shift 0
  for {set col 0} {$col<3} {incr col} {
   set m [signed [expr {@matrix@+2*(6+$col)}]]
   incr total [expr {$m*[lindex $input $col]}]
   incr shift [expr {($m*[signed [expr {@focus@+2*$col}]])>>14}]
  }
  if {($total>>14)-$shift+[signed @distance@]<48} {fail "floor near plane"}
 }}
 incr ::fit_checks
}
debug set_watchpoint write_mem @displayed_frames@ {} check_fit
'@
 $header=Get-Content "$root\build\$Profile\motion_data.h" -Raw
 foreach($entry in @{STRIDE='SAMPLE_STRIDE';PERBANK='POSES_PER_BANK';FRAMEBYTES='FRAME_BYTES';FLOOR='FLOOR_Y'}.GetEnumerator()) {$value=[regex]::Match($header,'#define '+$entry.Value+' (-?\d+)').Groups[1].Value;$tcl=$tcl.Replace("@$($entry.Key)@",$value)}
 $tcl=$tcl.Replace('@ROM@',$romPath.Replace('\','/')).Replace('note "PASS seconds=','note "FIT checks=$::fit_checks";note "PASS seconds=')
}
$tcl=$tcl.Replace('@FITASSERT@',$(if($Fit){'if {$::fit_checks<1} {fail "no fit checks"}'}else{''})).Replace('@MINBANK@',"$minBank").Replace('@MAXBANK@',"$maxBank")
$tcl=$tcl.Replace('@MINPOSE@',[string][Math]::Max(0,$motionFrames-30))
$cameraKeys=if($ManualCamera){@'
after time 2 {keymatrixdown 3 1};after time 2.3 {keymatrixup 3 1}
after time 3 {keymatrixdown 8 128;keymatrixdown 8 64}
after time 8 {keymatrixup 8 128;keymatrixup 8 64}
after time 9 {keymatrixdown 5 2;keymatrixdown 4 128}
after time 9.3 {keymatrixup 5 2;keymatrixup 4 128}
after time 11 {keymatrixdown 3 1};after time 11.3 {keymatrixup 3 1}
after time 13 {keymatrixdown 3 1};after time 13.3 {keymatrixup 3 1}
after time 15 {keymatrixdown 3 1};after time 15.3 {keymatrixup 3 1}
after time 17 {keymatrixdown 6 1;keymatrixdown 8 64}
after time 24 {keymatrixup 6 1;keymatrixup 8 64}
after time 26 {keymatrixdown 6 1;keymatrixdown 8 32}
after time 32 {keymatrixup 6 1;keymatrixup 8 32}
after time 34 {keymatrixdown 8 16;keymatrixdown 8 32}
after time 42 {keymatrixup 8 16;keymatrixup 8 32}
after time 46 {keymatrixdown 3 2};after time 46.3 {keymatrixup 3 2}
'@}else{''}
$tcl=$tcl.Replace('@CAMERAKEYS@',$cameraKeys)
$symbols=@('stage_ready','displayed_frames','vblank_ticks','video_error','motion_frame','selected_bank','playback_ticks','demo_loops','demo_wait','white_level','trails','reflection','actor_mode','music_ticks','matrix','focus','distance')
foreach($s in $symbols){$m=[regex]::Match($map,'(?m)^_'+$s+'\s*=\s*\$([0-9A-Fa-f]+)');if(!$m.Success){throw "Missing symbol: $s"};$tcl=$tcl.Replace("@$s@",[string][Convert]::ToInt32($m.Groups[1].Value,16))}
$record=if($Capture){'record start -doublesize "$::out/capture.avi"'}else{''}
$stop=if($Capture){'record stop'}else{''}
$tcl=$tcl.Replace('@OUT@',$out.Replace('\','/')).Replace('@SECONDS@',"$Seconds").Replace('@THROTTLE@',$(if($Realtime){'true'}else{'false'})).Replace('@CPU@',$(if($Machine -eq 'GT'){'r800'}else{'z80'})).Replace('@RECORD@',$record).Replace('@STOP@',$stop)
if($Headless){if($Capture){throw 'Capture needs a renderer'};$tcl="set renderer none`n"+$tcl}
[IO.File]::WriteAllText("$out/run.tcl",$tcl)
$env:OPENMSX_HOME="$out\home";$env:OPENMSX_USER_DATA="$RuntimeRoot\runtime\share";$env:OPENMSX_SYSTEM_DATA="$RuntimeRoot\emulator\share"
$taskArguments="-machine MOTION$Machine -ext geo3d -carta `"$romPath`" -romtype $mapper -script `"$out\run.tcl`""
$options=@{FilePath="$RuntimeRoot\emulator\openmsx.exe";ArgumentList=$taskArguments;WorkingDirectory=$root;WindowStyle='Hidden';PassThru=$true;RedirectStandardError="$out\stderr.txt";RedirectStandardOutput="$out\stdout.txt"}
if(!$Background){$options.Wait=$true}
$process=Start-Process @options
if($Background){[ordered]@{pid=$process.Id;profile=$Profile;machine=$Machine;start_utc=[DateTime]::UtcNow.ToString('o');seconds=$Seconds;realtime=[bool]$Realtime;headless=[bool]$Headless;sha256=(Get-FileHash $romPath -Algorithm SHA256).Hash.ToLowerInvariant()} | ConvertTo-Json | Set-Content "$out/process.json";Write-Output "START $Profile $Machine PID=$($process.Id) $out"}
else {if($process.ExitCode -or !(Select-String -Path "$out/events.txt" -Pattern '^PASS ') -or (Select-String -Path "$out/events.txt" -Pattern '^FAIL ')){throw "Verification failed: $out"};Write-Output "PASS $out"}
