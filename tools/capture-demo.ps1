$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force "$root\output","$root\output\capture-home" | Out-Null
if(Test-Path "$root\output\motion-stage-demo.avi"){
 Remove-Item -LiteralPath "$root\output\motion-stage-demo.avi" -Force
}
$script=@'
set save_settings_on_exit false
set throttle false
set sound_driver null
set minframeskip 0
set maxframeskip 0
set vsync off
set pause_on_lost_focus false
after time 6 {record start -doublesize {@ROOT@/output/motion-stage-demo.avi}}
after time 12 {keymatrixdown 5 2}
after time 12.5 {keymatrixup 5 2}
after time 18 {keymatrixdown 5 2;keymatrixdown 4 128}
after time 18.5 {keymatrixup 5 2;keymatrixup 4 128}
after time 24 {keymatrixdown 4 128}
after time 24.5 {keymatrixup 4 128}
after time 27 {keymatrixdown 3 1}
after time 27.5 {keymatrixup 3 1}
after time 30 {keymatrixdown 3 1}
after time 30.5 {keymatrixup 3 1}
after time 33 {keymatrixdown 3 1}
after time 33.5 {keymatrixup 3 1}
after time 36 {keymatrixdown 3 1}
after time 36.5 {keymatrixup 3 1}
after time 37 {keymatrixdown 8 128}
after time 38 {keymatrixup 8 128;keymatrixdown 8 32}
after time 39 {keymatrixup 8 32}
after time 41 {keymatrixdown 5 2;keymatrixdown 4 128}
after time 41.5 {keymatrixup 5 2;keymatrixup 4 128}
after time 44 {screenshot -raw {@ROOT@/output/demo-effects.png}}
after time 45 {keymatrixdown 5 2;keymatrixdown 4 128}
after time 45.5 {keymatrixup 5 2;keymatrixup 4 128}
after time 46 {screenshot -raw {@ROOT@/output/demo-final.png}}
after time 47 {keymatrixdown 3 4}
after time 47.3 {keymatrixup 3 4}
after time 47.9 {screenshot -raw {@ROOT@/output/demo-white.png}}
after time 48 {record stop;exit}
'@
$path="$root\output\capture.tcl"
[IO.File]::WriteAllText($path,$script.Replace('@ROOT@',$root.Replace('\','/')))
$env:OPENMSX_HOME="$root\output\capture-home"
$env:OPENMSX_USER_DATA="$root\runtime\share"
$env:OPENMSX_SYSTEM_DATA="$root\emulator\share"
$taskArguments="-machine MOTIONGT -ext geo3d -carta `"$root\build\MOTION.rom`" -romtype ASCII16-X -script `"$path`""
$p=Start-Process "$root\emulator\openmsx.exe" -ArgumentList $taskArguments -WorkingDirectory $root -WindowStyle Hidden -PassThru -Wait
if($p.ExitCode -ne 0){throw 'Demo capture failed'}
Write-Output "$root\output\motion-stage-demo.avi"
