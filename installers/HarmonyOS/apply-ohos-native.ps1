# Re-applies HarmonyOS native patches into ohos/ (EntryAbility, module.json5, strings).
# Safe after `flutter-oh.cmd create --platforms=ohos .` overwrites the tree.
# On a fresh clone, also copies build-profile.json5.example if the local
# (gitignored) build-profile.json5 is missing, and creates local.properties.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "paths.ps1")

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$NativeDir = Join-Path $PSScriptRoot "native"
$OhosDir = Join-Path $RepoRoot "ohos"
$EntryDst = Join-Path $OhosDir "entry\src\main\ets\entryability\EntryAbility.ets"
$ModuleDst = Join-Path $OhosDir "entry\src\main\module.json5"

if (-not (Test-Path $OhosDir)) {
  throw "ohos/ not found. Clone the HarmonyOS branch (ohos/ is tracked) or run: flutter-oh.cmd create --platforms=ohos ."
}

$ProfileDst = Join-Path $OhosDir "build-profile.json5"
$ProfileExample = Join-Path $OhosDir "build-profile.json5.example"
if (-not (Test-Path $ProfileDst)) {
  if (-not (Test-Path $ProfileExample)) {
    throw "Missing $ProfileExample"
  }
  Copy-Item $ProfileExample $ProfileDst
  Write-Host "Created ohos/build-profile.json5 from .example — configure Signing Configs in DevEco next"
}

# Flutter-OH hvigor plugin requires local.properties (gitignored).
# versionName/Code MUST be set — otherwise HAP falls back to 1.0 / versionCode 1
# and install fails with 9568263 (downgrade) against a real AppScope build.
$LocalProps = Join-Path $OhosDir "local.properties"
$FlutterOh = (Get-HarmonyFlutterOhRoot).Replace('\', '\\')
$HosSdk = (Get-HarmonyHosSdkDir).Replace('\', '\\')
$vn = "2.2.0"
$vc = "1"
$AppJson = Join-Path $OhosDir "AppScope\app.json5"
if (Test-Path $AppJson) {
  $appText = Get-Content $AppJson -Raw
  if ($appText -match '"versionName"\s*:\s*"([^"]+)"') { $vn = $Matches[1] }
  if ($appText -match '"versionCode"\s*:\s*(\d+)') { $vc = $Matches[1] }
}
$created = -not (Test-Path $LocalProps)
@"
hwsdk.dir=$HosSdk
flutter.sdk=$FlutterOh
flutter.versionName=$vn
flutter.versionCode=$vc
"@ | Set-Content -Path $LocalProps -Encoding ASCII
if ($created) {
  Write-Host "Created ohos/local.properties"
} else {
  Write-Host "Updated ohos/local.properties (SDK paths + version from AppScope)"
}
Write-Host "  flutter.sdk=$FlutterOh"
Write-Host "  hwsdk.dir=$HosSdk"
Write-Host "  flutter.versionName=$vn  flutter.versionCode=$vc"

Copy-Item (Join-Path $NativeDir "EntryAbility.ets") $EntryDst -Force
Write-Host "Applied EntryAbility.ets -> $EntryDst"

if (Test-Path (Join-Path $NativeDir "module.json5")) {
  Copy-Item (Join-Path $NativeDir "module.json5") $ModuleDst -Force
  Write-Host "Applied module.json5 -> $ModuleDst"
}

$MediaSrc = Join-Path $NativeDir "media"
if (Test-Path $MediaSrc) {
  $AppMedia = Join-Path $OhosDir "AppScope\resources\base\media"
  $EntryMedia = Join-Path $OhosDir "entry\src\main\resources\base\media"
  New-Item -ItemType Directory -Force -Path $AppMedia, $EntryMedia | Out-Null
  Copy-Item (Join-Path $MediaSrc "background.png") $AppMedia -Force
  Copy-Item (Join-Path $MediaSrc "foreground.png") $AppMedia -Force
  Copy-Item (Join-Path $MediaSrc "app_layered_image.json") $AppMedia -Force
  Copy-Item (Join-Path $MediaSrc "foreground.png") (Join-Path $AppMedia "app_icon.png") -Force
  Copy-Item (Join-Path $MediaSrc "background.png") $EntryMedia -Force
  Copy-Item (Join-Path $MediaSrc "foreground.png") $EntryMedia -Force
  Copy-Item (Join-Path $MediaSrc "layered_image.json") $EntryMedia -Force
  Copy-Item (Join-Path $MediaSrc "foreground.png") (Join-Path $EntryMedia "icon.png") -Force
  # Splash only — transparent logo; must NOT replace layered foreground/background.
  $StartIcon = Join-Path $MediaSrc "start_icon.png"
  if (Test-Path $StartIcon) {
    Copy-Item $StartIcon $EntryMedia -Force
  }
  Write-Host "Applied layered 1024 icons + start_icon (splash)"
}

$WriteStrings = Join-Path $NativeDir "_write_strings.py"
if (Test-Path $WriteStrings) {
  python $WriteStrings
  Write-Host "Upserted string resources (download permission reason)"
}

# Keep module.json5 ACL permissions in sync with native/module.json5
# (READ_WRITE_DOWNLOAD_DIRECTORY + READ_PASTEBOARD; Profile must list both).
$SyncModule = Join-Path $NativeDir "_sync_module_json5.py"
if (Test-Path $SyncModule) {
  python $SyncModule
  Write-Host "Synced module.json5 (download + pasteboard ACL)"
}

# If Signing Configs already exist, ensure Product is bound (avoids unsigned HAP).
& (Join-Path $PSScriptRoot "ensure-signing-config.ps1")

Write-Host "Done. Next: DevEco Signing Configs (if needed), then ensure-signing-config.ps1, Sync, Run."
