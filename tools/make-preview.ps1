param([string]$FFmpeg='ffmpeg')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!(Test-Path $FFmpeg)){
 $command=Get-Command $FFmpeg -ErrorAction SilentlyContinue
 if(!$command){throw 'Install FFmpeg on PATH or specify -FFmpeg'}
 $FFmpeg=$command.Source
}
$filter='fps=10,scale=480:360:flags=lanczos,split[a][b];[a]palettegen=max_colors=64:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3'
$p=Start-Process $FFmpeg -ArgumentList @('-hide_banner','-nostdin','-y','-t','30','-i','output/verify-8m-GT-aligned-certified/capture.avi','-filter_complex',$filter,'-map_metadata','-1','-loop','0','preview.gif') -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardError "$root\build\preview-encode.log" -PassThru -Wait
if($p.ExitCode -ne 0){throw 'GIF encoding failed; see build/preview-encode.log'}
Write-Output "$root\preview.gif"