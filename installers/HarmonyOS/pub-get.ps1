# Run pub get for HarmonyOS using local OH-adapted plugins.
# Prerequisites:
#   1. .\installers\HarmonyOS\prefetch-deps.ps1
#   2. Flutter-OH 3.41 (FLUTTER_OH_ROOT or default F:\flutter_flutter_ohos_341)
#
# Usage:
#   .\installers\HarmonyOS\pub-get.ps1

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "paths.ps1")

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$FlutterCmd = Join-Path $PSScriptRoot "flutter-oh.cmd"
$DepsRoot = Get-HarmonyOhosDepsRoot
$OverridesSrc = Join-Path $PSScriptRoot "pubspec_overrides.yaml"
$OverridesDst = Join-Path $ProjectRoot "pubspec_overrides.yaml"

# Keep shallow-clone Flutter-OH reporting 3.41.9 (needed for pub constraints).
& (Join-Path $PSScriptRoot "fix-flutter-version.ps1")

$required = @(
    "$DepsRoot\fluttertpc_file_picker\pubspec.yaml",
    "$DepsRoot\flutter_permission_handler\permission_handler\pubspec.yaml",
    "$DepsRoot\fluttertpc_open_filex\pubspec.yaml",
    "$DepsRoot\flutter_packages_path_provider\packages\path_provider\path_provider\pubspec.yaml",
    "$DepsRoot\flutter_packages_shared_preferences\packages\shared_preferences\shared_preferences\pubspec.yaml",
    "$DepsRoot\flutter_packages_url_launcher\packages\url_launcher\url_launcher\pubspec.yaml",
    "$DepsRoot\flutter_plus_plugins_connectivity\packages\connectivity_plus\connectivity_plus\pubspec.yaml",
    "$DepsRoot\flutter_plus_plugins_device_info\packages\device_info_plus\device_info_plus\pubspec.yaml",
    "$DepsRoot\fluttertpc_desktop_drop\packages\desktop_drop\pubspec.yaml"
)

foreach ($f in $required) {
    if (-not (Test-Path $f)) {
        Write-Error "Missing $f — run .\installers\HarmonyOS\prefetch-deps.ps1 first (or set OHOS_DEPS_ROOT)"
    }
}

# Rewrite default F:/ohos-deps-341 paths to this machine's OHOS_DEPS_ROOT.
$depsUri = ($DepsRoot -replace '\\', '/')
$overridesText = Get-Content $OverridesSrc -Raw
$overridesText = $overridesText -replace 'F:/ohos-deps-341', $depsUri
Set-Content -Path $OverridesDst -Value $overridesText -NoNewline
Write-Host "Installed pubspec_overrides.yaml (deps -> $DepsRoot)" -ForegroundColor Cyan

# CPF file_picker OH fork publishes as file_picker_ohos with a different entrypoint.
# Normalize Dart package + HarmonyOS HAR module name to file_picker so Flutter-OH
# injectNativeModules (uses Dart package name) matches module.json5.
$filePickerRoot = Join-Path $DepsRoot "fluttertpc_file_picker"
$filePickerPubspec = Join-Path $filePickerRoot "pubspec.yaml"
$fpContent = Get-Content $filePickerPubspec -Raw
if ($fpContent -match 'name:\s*file_picker_ohos' -or -not (Test-Path (Join-Path $filePickerRoot "lib\file_picker.dart"))) {
    $fpContent = $fpContent -replace 'name:\s*file_picker_ohos', 'name: file_picker'
    Set-Content -Path $filePickerPubspec -Value $fpContent -NoNewline

    $entry = @"
export './src/file_picker.dart';
export './src/platform_file.dart';
export './src/file_picker_result.dart';
export './src/file_picker_macos.dart';
export './src/linux/file_picker_linux.dart';
export './src/file_picker_io.dart';
export './src/windows/file_picker_windows_stub.dart'
    if (dart.library.ffi) './src/windows/file_picker_windows.dart';
"@
    Set-Content -Path (Join-Path $filePickerRoot "lib\file_picker.dart") -Value $entry -NoNewline

    Get-ChildItem $filePickerRoot -Recurse -Include *.dart -File | ForEach-Object {
        $c = Get-Content $_.FullName -Raw
        if ($c -match 'package:file_picker_ohos/') {
            $n = $c -replace 'package:file_picker_ohos/', 'package:file_picker/'
            Set-Content -Path $_.FullName -Value $n -NoNewline
        }
    }
    Write-Host "Normalized file_picker_ohos -> file_picker for Dart overrides" -ForegroundColor Yellow
}

# Keep HAR module name aligned with Dart package name (DevEco error 00303053).
$fpOhPackage = Join-Path $filePickerRoot "ohos\oh-package.json5"
$fpModuleJson = Join-Path $filePickerRoot "ohos\src\main\module.json5"
foreach ($p in @($fpOhPackage, $fpModuleJson)) {
    if (-not (Test-Path $p)) { continue }
    $c = Get-Content $p -Raw
    $n = $c -replace '"file_picker_ohos"', '"file_picker"'
    if ($n -ne $c) {
        Set-Content -Path $p -Value $n -NoNewline
        Write-Host "Renamed HAR module file_picker_ohos -> file_picker in $p" -ForegroundColor Yellow
    }
}

# Windows-only transitive dep conflicts between OH forks (win32 5.x vs 6.x).
# Broaden local constraints so OHOS resolution can use a single win32 major.
Get-ChildItem -Path $DepsRoot -Recurse -Filter pubspec.yaml |
    Where-Object { $_.FullName -notmatch '\\example\\|\\test\\' } |
    ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $updated = [regex]::Replace(
            $content,
            '(?m)^(?<indent>\s*)win32:\s*.+$',
            '${indent}win32: ">=5.9.0 <7.0.0"'
        )
        if ($updated -ne $content) {
            Set-Content -Path $_.FullName -Value $updated -NoNewline
            Write-Host ("Patched win32 in {0}" -f $_.FullName.Substring($DepsRoot.Length + 1)) -ForegroundColor Yellow
        }
    }

Set-Location $ProjectRoot
Write-Host "Running pub get (Flutter-OH 3.41)..." -ForegroundColor Cyan
& $FlutterCmd pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "pub get OK" -ForegroundColor Green
