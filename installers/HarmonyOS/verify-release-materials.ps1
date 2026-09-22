# Verify Release signing materials exist (does not read passwords).
# Usage:
#   .\installers\HarmonyOS\verify-release-materials.ps1
#   .\installers\HarmonyOS\verify-release-materials.ps1 -ReleaseDir "D:\keys\harmony-release"

param(
  [string]$ReleaseDir = "F:\harmony-signing\release"
)

$ErrorActionPreference = "Stop"

$required = @(
  "IcyEasySend-release.p12",
  "IcyEasySend-release.cer",
  "IcyEasySend-releaseRelease.p7b"
)

Write-Host "ReleaseDir: $ReleaseDir" -ForegroundColor Cyan
if (-not (Test-Path $ReleaseDir)) {
  Write-Host "MISSING directory" -ForegroundColor Red
  exit 1
}

$ok = $true
foreach ($name in $required) {
  $p = Join-Path $ReleaseDir $name
  if (Test-Path $p) {
    $len = (Get-Item $p).Length
    Write-Host ("  OK   {0}  ({1} bytes)" -f $name, $len) -ForegroundColor Green
  } else {
    Write-Host ("  MISS {0}" -f $name) -ForegroundColor Red
    $ok = $false
  }
}

# Warn if debug materials might be mixed in by mistake
$debugHint = Join-Path (Split-Path $ReleaseDir) "debug"
if (Test-Path $debugHint) {
  Write-Host "`nNote: debug materials are under $debugHint — do not point release cer/p7b there." -ForegroundColor DarkYellow
}

Write-Host "`nACL reminder: Release .p7b must include READ_WRITE_DOWNLOAD_DIRECTORY + READ_PASTEBOARD." -ForegroundColor Yellow
Write-Host "Next: DevEco Signing Configs → add config named 'release' with these three files (see release-signing.md)."

if (-not $ok) { exit 1 }
