param([ValidateSet('8m','2m')][string]$Profile='8m',[ValidateSet('GT','CB')][string]$Machine='GT',[switch]$Muted,[switch]$Effects,[switch]$Headless,[switch]$IRQTiming,[string]$Rom='',[string]$Map='',[string]$RuntimeRoot='',[string]$Label='fast')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!$RuntimeRoot){$RuntimeRoot=$root}
if(!$Rom){$Rom="$root\build\$(if($Profile -eq '2m'){'MOTION2.ROM'}else{'MOTION8.ROM'})"}
if(!$Map){$Map="$root\build\$Profile\STAGE.map"}
$mapText=Get-Content $Map -Raw
$out="$root\output\bench-$Profile-$Machine-$Label-$(if($Effects){'effects'}else{'plain'})-$(if($Muted){'off'}else{'on'})";New-Item -ItemType Directory -Force $out,"$out\home" | Out-Null
Copy-Item -LiteralPath $Rom -Destination "$out\benchmark.rom" -Force
$Rom="$out\benchmark.rom"
$tcl=@'
set save_settings_on_exit false
set throttle false
set sound_driver null
set minframeskip 0
set maxframeskip 0
set vsync off
set pause_on_lost_focus false
set out {@OUT@}
set log [open "$out/events.txt" w]
set begun 0
proc byte {a} {debug read memory $a}
proc word {a} {expr {[byte $a]+256*[byte [expr {$a+1}]]}}
proc note {s} {puts $::log $s;flush $::log}
proc sample {} {note "FRAME t=[machine_info time] count=[word @displayed_frames@] pose=[word @motion_frame@] music=[word @music_ticks@]";after time 1 sample}
proc measure {} {
 set ::first [word @displayed_frames@];set ::begin [machine_info time]
 after time 30 finish
}
proc finish {} {
 set dt [expr {[machine_info time]-$::begin}];set frames [expr {([word @displayed_frames@]-$::first)&65535}]
 note "RESULT frames=$frames seconds=$dt fps=[expr {$frames/$dt}] muted=[byte @music_enabled@] trails=[byte @trails@] reflection=[byte @reflection@]"
 catch {screenshot -raw "$::out/final.png"}
 close $::log;exit
}
proc begin {} {
 if {!$::begun && [word @stage_ready@]==19795 && [byte @demo_wait@]==0} {
  set ::begun 1
  # Actual keys enter manual mode: T once (on) or twice (off); R optionally.
  after time 1 {keymatrixdown 5 2}
  after time 1.3 {keymatrixup 5 2}
  @KEYS@
  after time 8 measure
  after time 8 sample
 }
}
debug set_watchpoint write_mem @demo_wait@ {} begin
after time 20 {if {!$::begun} {note "FAIL boot";exit}}
'@
$keys=if($Effects){'after time 2 {keymatrixdown 4 128};after time 2.3 {keymatrixup 4 128}'}else{'after time 2 {keymatrixdown 5 2};after time 2.3 {keymatrixup 5 2}'}
if($Muted){$keys+=';after time 3 {keymatrixdown 4 4};after time 3.3 {keymatrixup 4 4}'}
foreach($s in @('stage_ready','demo_wait','displayed_frames','motion_frame','music_ticks','music_enabled','trails','reflection')){$m=[regex]::Match($mapText,'(?m)^_'+$s+'\s*=\s*\$([0-9A-Fa-f]+)');if(!$m.Success){throw "Missing symbol $s"};$tcl=$tcl.Replace("@$s@",[string][Convert]::ToInt32($m.Groups[1].Value,16))}
if($Headless){$tcl="set renderer none`n"+$tcl}
if($IRQTiming) {
 foreach($s in @('music_tick','interrupt_handler')) {if(![regex]::IsMatch($mapText,'(?m)^_'+$s+'\s*=\s*\$([0-9A-Fa-f]+)')){throw "Missing symbol $s"}}
 $music=[Convert]::ToInt32([regex]::Match($mapText,'(?m)^_music_tick\s*=\s*\$([0-9A-Fa-f]+)').Groups[1].Value,16)
 $irq=[Convert]::ToInt32([regex]::Match($mapText,'(?m)^_interrupt_handler\s*=\s*\$([0-9A-Fa-f]+)').Groups[1].Value,16)
 $image=[IO.File]::ReadAllBytes($Rom)
 $code=$image[16384..32767]
 $return=0
 for($i=$irq-0x8400;$i -lt $irq-0x8400+100;$i++){if($code[$i] -eq 205 -and $code[$i+1] -eq ($music -band 255) -and $code[$i+2] -eq ($music -shr 8)){$return=$i+0x8400+3;break}}
 if(!$return){throw 'Cannot locate music call return'}
 $tcl=$tcl.Replace('set ::first [word','set ::psg_sum 0;set ::psg_count 0;set ::measuring 1;set ::first [word').Replace('note "RESULT frames=', 'if {$::psg_count<1} {note "FAIL no PSG measurements";close $::log;exit};note "PSG mean_us=[expr {$::psg_sum*1000000/$::psg_count}] samples=$::psg_count";note "RESULT frames=')
 $tcl+="`nset measuring 0`nset psg_active 0`ndebug set_bp $music {} {if {`$::measuring} {set ::psg_begin [machine_info time];set ::psg_active 1}}`ndebug set_bp $return {} {if {`$::measuring && `$::psg_active} {incr ::psg_count;set ::psg_sum [expr {`$::psg_sum+[machine_info time]-`$::psg_begin}];set ::psg_active 0}}`n"
}
$tcl=$tcl.Replace('@OUT@',$out.Replace('\','/')).Replace('@KEYS@',$keys)
[IO.File]::WriteAllText("$out/run.tcl",$tcl)
$env:OPENMSX_HOME="$out\home";$env:OPENMSX_USER_DATA="$RuntimeRoot\runtime\share";$env:OPENMSX_SYSTEM_DATA="$RuntimeRoot\emulator\share"
$taskArguments="-machine MOTION$Machine -ext geo3d -carta `"$Rom`" -romtype $(if($Profile -eq '2m'){'ASCII16'}else{'ASCII16-X'}) -script `"$out\run.tcl`""
$p=Start-Process "$RuntimeRoot\emulator\openmsx.exe" -ArgumentList $taskArguments -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardError "$out/stderr.txt" -RedirectStandardOutput "$out/stdout.txt"
Write-Output "START BENCH $out PID=$($p.Id)"
