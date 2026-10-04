param([ValidateSet('8m','2m')][string]$Profile='8m',[ValidateSet('GT','CB')][string]$Machine='GT',[string]$RuntimeRoot='')
$ErrorActionPreference='Stop'
& "$PSScriptRoot\verify-demo.ps1" -Profile $Profile -Machine $Machine -Seconds 150 -Headless -Fit -RuntimeRoot $RuntimeRoot -Label '-test'
& "$PSScriptRoot\verify-controls.ps1" -Profile $Profile -Machine $Machine -RuntimeRoot $RuntimeRoot
