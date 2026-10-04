param()
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
 $files=@(git -c core.quotepath=false ls-files --cached --others --exclude-standard)
 if($LASTEXITCODE -ne 0){throw 'Git candidate-file inventory failed'}
 $files=@($files | Sort-Object -Unique)
 $privatePattern='(?i)[A-Z]:[\\/]Users[\\/][^\s<>"'']+|[A-Z]:[\\/]work[\\/]|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-(?:proj-|ant-)?[A-Za-z0-9_-]{24,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|https?://[^/\s]+:[^/\s]+@'
 $forbidden='^(?:runtime|emulator|build|output|\.claude|\.codex)/|(?:^|/)\.env(?:\.|$)|\.bvh$|\.avi$|\.log$'
 $issues=@()
 foreach($file in $files){
  if($file -match $forbidden){$issues += "Excluded local file is a Git candidate: $file";continue}
  if(!(Test-Path -LiteralPath $file)){continue}
  if($file -match '\.(gif|mp4)$'){continue}
  $content=if($file -match '\.rom$'){[Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes((Join-Path $root $file)))}else{[IO.File]::ReadAllText((Join-Path $root $file))}
  if($content -match $privatePattern){$issues += "Possible private path or credential in $file (matched value withheld)"}
 }
 foreach($file in @('dist/MOTION8.ROM','dist/MOT8N.ROM','dist/MOTION2.ROM','dist/MOT2N.ROM','dist/motion-stage-demo.mp4','preview.gif')){
  if($files -notcontains $file){$issues += "Missing public artifact: $file"}
 }
 foreach($file in ($files | Where-Object {$_ -match '\.md$'})){
  $content=[IO.File]::ReadAllText((Join-Path $root $file))
  foreach($link in [regex]::Matches($content,'\]\(([^)]+)\)')){
   $target=$link.Groups[1].Value
   if($target -match '^(?:https?://|#)'){continue}
   $resolved=Join-Path (Split-Path (Join-Path $root $file) -Parent) ($target -split '#')[0]
   if(!(Test-Path -LiteralPath $resolved)){$issues += "Broken local link in $file : $target"}
  }
 }
 $manifest=Get-Content -LiteralPath "$root/dist/manifest.json" -Raw | ConvertFrom-Json
 $sums=@{}
 foreach($line in [IO.File]::ReadAllLines("$root/dist/SHA256SUMS.txt")){
  if($line -notmatch '^([0-9a-f]{64})  ([A-Za-z0-9_.-]+)$'){throw 'Malformed checksum entry'}
  $sums[$matches[2]]=$matches[1]
 }
 foreach($entry in $manifest.files){
  if($entry.file -notmatch '^[A-Za-z0-9_.-]+$'){throw 'Unsafe manifest artifact name'}
  $path=Join-Path "$root/dist" $entry.file
  $sha=[Security.Cryptography.SHA256]::Create()
  try {$actual=[BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($path))).Replace('-','').ToLowerInvariant()}
  finally {$sha.Dispose()}
  if($actual -ne $entry.sha256 -or $actual -ne $sums[$entry.file] -or (Get-Item -LiteralPath $path).Length -ne $entry.bytes){$issues += "Artifact hash/size mismatch: $($entry.file)"}
 }
 foreach($name in @('MOTION8.ROM','MOT8N.ROM','MOTION2.ROM','MOT2N.ROM','motion-stage-demo.mp4')){
  if(@($manifest.files | Where-Object file -eq $name).Count -ne 1 -or !$sums.ContainsKey($name)){$issues += "Missing/duplicate manifest artifact: $name"}
 }
 foreach($file in ($files | Where-Object {$_ -match '\.md$'})){
  $other=if($file -match '\.ja\.md$'){$file -replace '\.ja\.md$','.md'}else{$file -replace '\.md$','.ja.md'}
  if($files -notcontains $other){$issues += "Missing language counterpart: $file"}
  $text=[IO.File]::ReadAllText((Join-Path $root $file))
  if($text -notmatch '^\[English\]\([^\r\n]+\) \| \[\u65e5\u672c\u8a9e\]\('){$issues += "Missing language links: $file"}
 }
 if($issues.Count){$issues | ForEach-Object {Write-Output $_};throw 'Release audit found issues'}
 Write-Output "PASS: $($files.Count) Git candidate files; no detected private paths or credential patterns; release links resolve."
 Write-Output 'This scans the publication set, not ignored local runtime files. It is a heuristic audit, not a guarantee.'
}finally{Pop-Location}
