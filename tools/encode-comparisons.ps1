param([string]$FFmpeg='ffmpeg')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
Set-Location $root
New-Item -ItemType Directory -Force "$root\output\report","$root\build\media" | Out-Null
Copy-Item (Join-Path $env:WINDIR 'Fonts\consolab.ttf') "$root\build\media\font.ttf" -Force
function Encode($items,$log) {
 $quoted=foreach($item in $items){'"'+($item -replace '(\\*)"','$1$1\"' -replace '(\\+)$','$1$1')+'"'}
 $process=Start-Process $FFmpeg -ArgumentList ($quoted -join ' ') -WorkingDirectory $root -WindowStyle Hidden -PassThru -Wait -RedirectStandardError "$root\build\media\$log"
 if($process.ExitCode){throw "FFmpeg failed: $log"}
}
foreach($machine in @('GT','CB')) {
 $cpu=if($machine -eq 'GT'){'R800'}else{'Z80'}
 $inputs=@('-i',"output/verify-8m-$machine-aligned-certified/capture.avi",'-i',"output/verify-2m-$machine-aligned-certified/capture.avi")
 $filter="[0:v]bwdif=mode=send_frame:parity=auto:deint=all,scale=480:360:flags=lanczos,pad=480:400:0:40:color=0x0b1524,drawtext=fontfile=build/media/font.ttf:text='8 MiB - 20 Hz - $cpu':x=12:y=11:fontsize=19:fontcolor=white[a];[1:v]bwdif=mode=send_frame:parity=auto:deint=all,scale=480:360:flags=lanczos,pad=480:400:0:40:color=0x0b1524,drawtext=fontfile=build/media/font.ttf:text='2 MiB - 10 Hz - $cpu':x=12:y=11:fontsize=19:fontcolor=white[b];[a][b]hstack=inputs=2[v]"
 Encode (@('-hide_banner','-nostdin','-y')+$inputs+@('-filter_complex',$filter,'-map','[v]','-map','0:a','-t','71.4','-map_metadata','-1','-c:v','libx264','-preset','medium','-crf','23','-pix_fmt','yuv420p','-af','volume=10dB','-c:a','aac','-b:a','96k','-movflags','+faststart',"output/report/comparison-$($cpu.ToLower()).mp4")) "compare-$cpu.log"
}
Encode @('-hide_banner','-nostdin','-y','-i','output/verify-8m-GT-aligned-certified/capture.avi','-t','71.4','-vf',"bwdif=mode=send_frame:parity=auto:deint=all,scale=640:480:flags=lanczos,drawtext=fontfile=build/media/font.ttf:text='GEO3D MOTION STAGE - 8 MiB - R800':x=12:y=10:fontsize=17:fontcolor=white:box=1:boxcolor=black@0.6",'-map_metadata','-1','-c:v','libx264','-preset','medium','-crf','23','-pix_fmt','yuv420p','-af','volume=10dB','-c:a','aac','-b:a','96k','-movflags','+faststart','output/motion-stage-demo.mp4') 'demo.log'
Write-Output 'Encoded two comparisons and the complete ROM-native demo.'
