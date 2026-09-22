# Load HarmonyOS / Flutter-OH 3.41.9 dev environment for THIS PowerShell session only.
# Usage (from repo root):
#   . .\installers\HarmonyOS\activate.ps1

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "paths.ps1")

$DevecoRoot = Get-HarmonyDevecoRoot
$FlutterOhRoot = Get-HarmonyFlutterOhRoot
$OhosSdk = Get-HarmonyHosSdkDir
$JavaHome = Join-Path $DevecoRoot "jbr"

$prefix = @(
    "$JavaHome\bin",
    "$DevecoRoot\tools\node",
    "$DevecoRoot\tools\ohpm\bin",
    "$DevecoRoot\tools\hvigor\bin",
    "$FlutterOhRoot\bin"
) -join ';'

$env:PATH = "$prefix;" + $env:PATH
$env:JAVA_HOME = $JavaHome
$env:FLUTTER_OH_ROOT = $FlutterOhRoot
$env:FLUTTER_GIT_URL = "https://gitcode.com/CPF-Flutter/flutter_flutter.git"
$env:HOS_SDK_HOME = $OhosSdk
$env:DEVECO_SDK_HOME = $OhosSdk
$env:DEVECO_ROOT = $DevecoRoot
$env:OHOS_DEPS_ROOT = Get-HarmonyOhosDepsRoot

function global:flutter-oh {
    & "$FlutterOhRoot\bin\flutter.bat" @args
}

Write-Host "HarmonyOS Flutter-OH 3.41 session active." -ForegroundColor Green
Write-Host "  flutter-oh -> $FlutterOhRoot"
Write-Host "  HOS_SDK_HOME -> $OhosSdk"
Write-Host "  OHOS_DEPS_ROOT -> $($env:OHOS_DEPS_ROOT)"
Write-Host "Try: flutter-oh doctor -v"
