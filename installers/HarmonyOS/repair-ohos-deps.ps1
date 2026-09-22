# Restore deleted tracked files under F:\ohos-deps-341 plugin checkouts.
# DevEco / ohpm clean sometimes removes plugin ohos/ sources (e.g. build-profile.json5),
# which then breaks Sync with: Can not find build config file build-profile.json5 at '…'.
#
# Usage (from repo root):
#   .\installers\HarmonyOS\repair-ohos-deps.ps1

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "paths.ps1")
$DepsRoot = Get-HarmonyOhosDepsRoot

if (-not (Test-Path $DepsRoot)) {
  throw "Missing $DepsRoot — run prefetch-deps.ps1 first (or set OHOS_DEPS_ROOT)."
}

$repos = Get-ChildItem $DepsRoot -Directory | Where-Object {
  Test-Path (Join-Path $_.FullName ".git")
}

foreach ($repo in $repos) {
  Write-Host "Restoring tracked files in $($repo.Name)..." -ForegroundColor Cyan
  git -C $repo.FullName -c core.longpaths=true checkout -- .
}

# pub-get.ps1 renames file_picker_ohos HAR -> file_picker; restore undoes that.
$fpOhPackage = Join-Path $DepsRoot "fluttertpc_file_picker\ohos\oh-package.json5"
$fpModuleJson = Join-Path $DepsRoot "fluttertpc_file_picker\ohos\src\main\module.json5"
foreach ($p in @($fpOhPackage, $fpModuleJson)) {
  if (-not (Test-Path $p)) { continue }
  $c = Get-Content $p -Raw
  $n = $c -replace '"file_picker_ohos"', '"file_picker"'
  if ($n -ne $c) {
    Set-Content -Path $p -Value $n -NoNewline
    Write-Host "Re-applied file_picker HAR rename in $p" -ForegroundColor Yellow
  }
}

Write-Host "`nDone. Prefer also: .\installers\HarmonyOS\pub-get.ps1" -ForegroundColor Green
Write-Host "Then in DevEco (ohos project): Sync and Refresh Project / Run."
Write-Host "Critical check (connectivity_plus):"
$probe = Join-Path $DepsRoot "flutter_plus_plugins_connectivity\packages\connectivity_plus\connectivity_plus\ohos\build-profile.json5"
if (Test-Path $probe) {
  Write-Host "  OK  $probe" -ForegroundColor Green
} else {
  Write-Host "  MISSING $probe — re-run prefetch-deps.ps1" -ForegroundColor Red
  exit 1
}
