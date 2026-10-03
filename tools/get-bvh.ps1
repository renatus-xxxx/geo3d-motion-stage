$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$expected=@{
 aachan='3DD0FE567CB4A2D02E497C3F67544BA3ADC702C901AC712742B0A6E3010FC9A4'
 kashiyuka='43341589005EA862D026822E8E3363E59A93C9C09BCBEC71D61BFEBE879900B8'
 nocchi='A1556C346E056911FE15B7E363744CAB3B36EA515CF23CD5A0D93ED590AD72F3'
}
New-Item -ItemType Directory -Force "$root\assets" | Out-Null

& {
 foreach($name in @('aachan','kashiyuka','nocchi')){
  $path="$root\assets\$name.bvh"
  if(!(Test-Path $path)){throw "Missing $name.bvh. Place the official project BVH files in assets/. See THIRD_PARTY.md."}
  $sha=[Security.Cryptography.SHA256]::Create()
  $hash=[BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($path))).Replace('-','')
  $sha.Dispose()
  if($hash -ne $expected[$name]){throw "$name.bvh does not match the supported BVH SHA-256"}
  Write-Output "$name.bvh verified"
 }
}
