param([ValidateSet('8m','2m','all')][string]$Profile='all',[ValidateSet('GT','CB','all')][string]$Machine='all',[string]$RuntimeRoot='')
$ErrorActionPreference='Stop'
foreach($p in $(if($Profile -eq 'all'){@('8m','2m')}else{@($Profile)})) {
 foreach($m in $(if($Machine -eq 'all'){@('GT','CB')}else{@($Machine)})) {
  & "$PSScriptRoot\verify-demo.ps1" -Profile $p -Machine $m -Seconds 85 -Capture -Fit -RuntimeRoot $RuntimeRoot -Label '-aligned-certified'
 }
}
