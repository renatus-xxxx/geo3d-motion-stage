param([ValidateSet('8m','2m')][string]$Profile='8m')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$map=Get-Content "$root\build\$Profile\STAGE.map" -Raw
$ready=[Convert]::ToInt32([regex]::Match($map,'(?m)^_stage_ready\s*=\s*\$([0-9A-Fa-f]+)').Groups[1].Value,16)
foreach($machine in @('GT','CB')){
 $out="$root\output\launcher-$Profile-$machine"
 New-Item -ItemType Directory -Force $out | Out-Null
 $script=@'
set log [open {@OUT@/result.txt} w]
puts $log "launch_settings throttle=[set throttle] speed=[set speed]"
flush $log
after time 12 {
 set ready [expr {[debug read memory @READY@]+256*[debug read memory @READY_HIGH@]}]
 puts $::log "ready=$ready cpu=[get_active_cpu]"
 screenshot -raw {@OUT@/screen.png}
 close $::log
 exit
}
'@
 $script=$script.Replace('@OUT@',$out.Replace('\','/')).Replace('@READY@',[string]$ready).Replace('@READY_HIGH@',[string]($ready+1))
 $path="$out\test.tcl"
 [IO.File]::WriteAllText($path,$script)
 $bat=if($machine -eq 'GT'){'run-turbor.bat'}else{'run-msx2plus-cbios.bat'}
 $taskArguments='/d /c ""'+$root+'\'+$bat+'" '+$Profile+' -script "'+$path+'""'
 $p=Start-Process cmd.exe -ArgumentList $taskArguments -WorkingDirectory $root -WindowStyle Hidden -PassThru -Wait
 if($p.ExitCode -ne 0){throw "$bat failed"}
 $result=Get-Content "$out\result.txt"
 if(!($result -match 'ready=19795') -or !($result -match 'throttle=true speed=100')){throw "$bat did not start at native speed"}
 $cpu=if($machine -eq 'GT'){'r800'}else{'z80'}
 if(!($result -match "cpu=$cpu")){throw "$bat used the wrong CPU"}
 Write-Output "PASS $bat"
}
