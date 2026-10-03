param([string]$FFmpeg='ffmpeg')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!(Test-Path $FFmpeg)){
 $command=Get-Command $FFmpeg -ErrorAction SilentlyContinue
 if(!$command){throw 'Install FFmpeg on PATH or specify -FFmpeg'}
 $FFmpeg=$command.Source
}
Copy-Item -LiteralPath (Join-Path $env:WINDIR 'Fonts\consolab.ttf') -Destination "$root\build\demo-font.ttf" -Force
$filter=@'
drawtext=fontfile=build/demo-font.ttf:text='GEO3D / SCREEN 7 FIL / R800':x=12:y=8:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.65:enable='lt(t,6)',
drawtext=fontfile=build/demo-font.ttf:text='T - TRAILS ON / TWO PAST POSES':x=12:y=8:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.65:enable='gte(t,6)*lt(t,12)',
drawtext=fontfile=build/demo-font.ttf:text='T - TRAILS OFF / R - REFLECTION ON':x=12:y=8:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.65:enable='gte(t,12)*lt(t,18)',
drawtext=fontfile=build/demo-font.ttf:text='R - REFLECTION OFF':x=12:y=8:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.65:enable='gte(t,18)*lt(t,21)',
drawtext=fontfile=build/demo-font.ttf:text='C - CHARACTER / AACHAN':x=12:y=8:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.65:enable='gte(t,21)*lt(t,24)',
drawtext=fontfile=build/demo-font.ttf:text='C - CHARACTER / KASHIYUKA':x=12:y=8:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.65:enable='gte(t,24)*lt(t,27)',
drawtext=fontfile=build/demo-font.ttf:text='C - CHARACTER / NOCCHI':x=12:y=8:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.65:enable='gte(t,27)*lt(t,30)',
drawtext=fontfile=build/demo-font.ttf:text='C - ALL THREE / CAMERA ROTATION':x=12:y=8:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.65:enable='gte(t,30)*lt(t,35)',
drawtext=fontfile=build/demo-font.ttf:text='T + R - TRAILS AND REFLECTION ON':x=12:y=8:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.65:enable='gte(t,35)*lt(t,39)',
drawtext=fontfile=build/demo-font.ttf:text='T + R - BOTH OFF / 8MB ASCII16-X ROM':x=12:y=8:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.65:enable='gte(t,39)*lt(t,41)'
'@
[IO.File]::WriteAllText("$root\build\demo-filter.txt",$filter.Replace("`r`n","`n"),[Text.Encoding]::ASCII)
$taskArguments='-hide_banner -nostdin -y -i output/motion-stage-demo.avi -filter_script:v build/demo-filter.txt -map_metadata -1 -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -af volume=10dB,afade=t=out:st=41.2:d=0.8 -c:a aac -b:a 128k -movflags +faststart output/motion-stage-demo.mp4'
$p=Start-Process $FFmpeg -ArgumentList $taskArguments -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardError "$root\build\demo-encode.log" -Wait -PassThru
if($p.ExitCode -ne 0){throw 'MP4 encoding failed; see build/demo-encode.log'}
New-Item -ItemType Directory -Force "$root\dist" | Out-Null
Copy-Item -LiteralPath "$root\output\motion-stage-demo.mp4" -Destination "$root\dist\motion-stage-demo.mp4" -Force
Write-Output "$root\dist\motion-stage-demo.mp4"
