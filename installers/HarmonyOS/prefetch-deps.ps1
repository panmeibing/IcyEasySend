# Prefetch OpenHarmony-adapted Flutter plugins for Flutter-OH 3.41.
# Usage:
#   .\installers\HarmonyOS\prefetch-deps.ps1

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "paths.ps1")
$DepsRoot = Get-HarmonyOhosDepsRoot
New-Item -ItemType Directory -Force -Path $DepsRoot | Out-Null
Write-Host "OH plugin cache: $DepsRoot" -ForegroundColor Cyan

# Windows path-length fix for monorepos such as flutter_packages.
git config --global core.longpaths true

function Ensure-Repo {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Branch,
        [string[]]$SparsePaths = @()
    )

    $TargetDir = Join-Path $DepsRoot $Name

    if (Test-Path (Join-Path $TargetDir ".git")) {
        Write-Host "Updating $Name ($Branch)..." -ForegroundColor Cyan
        git -C $TargetDir -c core.longpaths=true fetch --depth 1 origin $Branch
        git -C $TargetDir -c core.longpaths=true checkout -B $Branch FETCH_HEAD
        return
    }

    Write-Host "Cloning $Name ($Branch)..." -ForegroundColor Cyan
    if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }

    if ($SparsePaths.Count -gt 0) {
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
        git -C $TargetDir -c core.longpaths=true init
        git -C $TargetDir remote add origin $Url
        git -C $TargetDir -c core.longpaths=true sparse-checkout init --cone
        git -C $TargetDir -c core.longpaths=true sparse-checkout set @SparsePaths
        git -C $TargetDir -c core.longpaths=true fetch --depth 1 origin $Branch
        git -C $TargetDir -c core.longpaths=true checkout -B $Branch FETCH_HEAD
    }
    else {
        git -c core.longpaths=true clone --branch $Branch --single-branch --depth 1 $Url $TargetDir
    }
}

# Standalone plugin repos
Ensure-Repo -Name "fluttertpc_file_picker" `
    -Url "https://gitcode.com/CPF-Flutter/fluttertpc_file_picker.git" `
    -Branch "br_v10.3.8_ohos"

Ensure-Repo -Name "flutter_permission_handler" `
    -Url "https://gitcode.com/CPF-Flutter/flutter_permission_handler.git" `
    -Branch "br_v12.0.1_ohos"

Ensure-Repo -Name "fluttertpc_open_filex" `
    -Url "https://gitcode.com/CPF-Flutter/fluttertpc_open_filex.git" `
    -Branch "br_v4.5.0_ohos"

Ensure-Repo -Name "fluttertpc_wakelock_plus" `
    -Url "https://gitcode.com/CPF-Flutter/fluttertpc_wakelock_plus.git" `
    -Branch "br_3.41_dev"

Ensure-Repo -Name "fluttertpc_receive_sharing_intent" `
    -Url "https://gitcode.com/CPF-Flutter/fluttertpc_receive_sharing_intent.git" `
    -Branch "br_v1.8.1_ohos"

Ensure-Repo -Name "fluttertpc_desktop_drop" `
    -Url "https://gitcode.com/CPF-Flutter/fluttertpc_desktop_drop.git" `
    -Branch "br_3.27"

# Monorepos — sparse checkout to avoid Windows MAX_PATH failures
Ensure-Repo -Name "flutter_packages_path_provider" `
    -Url "https://gitcode.com/CPF-Flutter/flutter_packages.git" `
    -Branch "br_path_provider-v2.1.5_ohos" `
    -SparsePaths @(
        "packages/path_provider/path_provider",
        "packages/path_provider/path_provider_ohos",
        "packages/path_provider/path_provider_platform_interface"
    )

Ensure-Repo -Name "flutter_packages_shared_preferences" `
    -Url "https://gitcode.com/CPF-Flutter/flutter_packages.git" `
    -Branch "br_shared_preferences-v2.5.4_ohos" `
    -SparsePaths @(
        "packages/shared_preferences/shared_preferences",
        "packages/shared_preferences/shared_preferences_ohos",
        "packages/shared_preferences/shared_preferences_platform_interface"
    )

Ensure-Repo -Name "flutter_packages_url_launcher" `
    -Url "https://gitcode.com/CPF-Flutter/flutter_packages.git" `
    -Branch "br_url_launcher-v6.3.2_ohos" `
    -SparsePaths @(
        "packages/url_launcher/url_launcher",
        "packages/url_launcher/url_launcher_ohos",
        "packages/url_launcher/url_launcher_platform_interface"
    )

Ensure-Repo -Name "flutter_plus_plugins_connectivity" `
    -Url "https://gitcode.com/CPF-Flutter/flutter_plus_plugins.git" `
    -Branch "br_connectivity_plus-v7.0.0_ohos" `
    -SparsePaths @(
        "packages/connectivity_plus/connectivity_plus",
        "packages/connectivity_plus/connectivity_plus_platform_interface"
    )

Ensure-Repo -Name "flutter_plus_plugins_device_info" `
    -Url "https://gitcode.com/CPF-Flutter/flutter_plus_plugins.git" `
    -Branch "br_device_info_plus-v12.3.0_ohos" `
    -SparsePaths @(
        "packages/device_info_plus/device_info_plus",
        "packages/device_info_plus/device_info_plus_platform_interface"
    )

Write-Host "`nPrefetch complete -> $DepsRoot" -ForegroundColor Green
Get-ChildItem $DepsRoot -Directory | ForEach-Object { " - $($_.Name)" }
