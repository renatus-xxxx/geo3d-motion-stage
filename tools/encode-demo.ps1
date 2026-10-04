param([string]$FFmpeg='ffmpeg')
$ErrorActionPreference='Stop'
& "$PSScriptRoot\encode-comparisons.ps1" -FFmpeg $FFmpeg
