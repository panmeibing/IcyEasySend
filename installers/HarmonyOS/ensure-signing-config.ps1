# Bind products[].signingConfig to the first signingConfigs[].name when missing.
# DevEco "Automatically generate signature" often writes signingConfigs but leaves
# the Product unbound → assemble installs entry-default-unsigned.hap → 9568320.
#
# Usage (from repo root, after Signing Configs Apply):
#   .\installers\HarmonyOS\ensure-signing-config.ps1

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Profile = Join-Path $RepoRoot "ohos\build-profile.json5"

if (-not (Test-Path $Profile)) {
  throw "Missing $Profile — run apply-ohos-native.ps1 first, then configure Signing Configs."
}

$raw = Get-Content $Profile -Raw

if ($raw -notmatch '"signingConfigs"\s*:\s*\[\s*\{') {
  Write-Host "No signingConfigs yet. In DevEco: Project Structure → Signing Configs → Automatically generate signature → Apply." -ForegroundColor Yellow
  exit 0
}

if ($raw -notmatch '"signingConfigs"\s*:\s*\[\s*\{\s*"name"\s*:\s*"([^"]+)"') {
  Write-Host "Could not parse signingConfigs[0].name — open build-profile.json5 and set products[0].signingConfig manually." -ForegroundColor Yellow
  exit 1
}
$sigName = $Matches[1]

if ($raw -match '"signingConfig"\s*:\s*"([^"]+)"') {
  Write-Host "Product already bound: signingConfig=$($Matches[1])" -ForegroundColor Green
  exit 0
}

# Insert into the first product object (name: default).
$pattern = '("products"\s*:\s*\[\s*\{\s*"name"\s*:\s*"default")'
if ($raw -notmatch $pattern) {
  Write-Host "Could not find products[0] name=default — set signingConfig manually in DevEco Project Structure → Products." -ForegroundColor Yellow
  exit 1
}

$updated = [regex]::Replace(
  $raw,
  $pattern,
  "`$1,`r`n        `"signingConfig`": `"$sigName`"",
  1
)

if ($updated -eq $raw) {
  throw "Failed to insert signingConfig"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($Profile, $updated, $utf8NoBom)
Write-Host "Bound products.default.signingConfig = `"$sigName`"" -ForegroundColor Green
Write-Host "Next: DevEco Sync and Refresh Project, then Run (expect entry-default-signed.hap)."
