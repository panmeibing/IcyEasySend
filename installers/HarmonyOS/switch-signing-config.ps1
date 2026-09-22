# Switch products.default.signingConfig to an existing signingConfigs name.
# Usage:
#   .\installers\HarmonyOS\switch-signing-config.ps1 -Name default   # daily Run
#   .\installers\HarmonyOS\switch-signing-config.ps1 -Name release   # Build APP / release HAP

param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("default", "release", "debug")]
  [string]$Name
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Profile = Join-Path $RepoRoot "ohos\build-profile.json5"

if (-not (Test-Path $Profile)) {
  throw "Missing $Profile — run apply-ohos-native.ps1 and configure Signing Configs first."
}

$raw = Get-Content $Profile -Raw

# Confirm the named signingConfig exists
$configPattern = '"name"\s*:\s*"' + [regex]::Escape($Name) + '"'
# Look under signingConfigs block only (rough check)
if ($raw -notmatch ('"signingConfigs"\s*:\s*\[[\s\S]*?' + $configPattern)) {
  Write-Host "signingConfigs has no entry named `"$Name`"." -ForegroundColor Red
  Write-Host "Add it in DevEco: Project Structure → Signing Configs (see release-signing.md)." -ForegroundColor Yellow
  exit 1
}

if ($raw -match '"signingConfig"\s*:\s*"([^"]+)"') {
  $current = $Matches[1]
  if ($current -eq $Name) {
    Write-Host "Already bound: products.default.signingConfig = `"$Name`"" -ForegroundColor Green
    exit 0
  }
  $updated = [regex]::Replace($raw, '"signingConfig"\s*:\s*"[^"]+"', "`"signingConfig`": `"$Name`"", 1)
} else {
  $pattern = '("products"\s*:\s*\[\s*\{\s*"name"\s*:\s*"default")'
  if ($raw -notmatch $pattern) {
    throw "Could not find products[0] name=default"
  }
  $updated = [regex]::Replace(
    $raw,
    $pattern,
    "`$1,`r`n        `"signingConfig`": `"$Name`"",
    1
  )
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($Profile, $updated, $utf8NoBom)
Write-Host "Bound products.default.signingConfig = `"$Name`"" -ForegroundColor Green
if ($Name -eq "release") {
  Write-Host "Next: Sync → Build APP(s) / build hap --release. Then switch back to default for daily Run."
} else {
  Write-Host "Next: Sync → Run (debug)."
}
