# Shared path defaults for HarmonyOS scripts.
# Override via environment variables before running any installer script:
#   $env:FLUTTER_OH_ROOT  = "D:\sdk\flutter_flutter_ohos_341"
#   $env:OHOS_DEPS_ROOT   = "D:\sdk\ohos-deps-341"
#   $env:HOS_SDK_HOME     = "D:\sdk\harmony-sdk\default"
#   $env:DEVECO_ROOT      = "C:\Program Files\Huawei\DevEco Studio"

function Get-HarmonyDevecoRoot {
  if ($env:DEVECO_ROOT -and (Test-Path $env:DEVECO_ROOT)) { return $env:DEVECO_ROOT }
  $fallback = "C:\Program Files\Huawei\DevEco Studio"
  if (Test-Path $fallback) { return $fallback }
  throw "DevEco Studio not found. Set DEVECO_ROOT."
}

function Get-HarmonyFlutterOhRoot {
  if ($env:FLUTTER_OH_ROOT -and (Test-Path (Join-Path $env:FLUTTER_OH_ROOT "bin\flutter.bat"))) {
    return $env:FLUTTER_OH_ROOT
  }
  $fallback = "F:\flutter_flutter_ohos_341"
  if (Test-Path (Join-Path $fallback "bin\flutter.bat")) { return $fallback }
  throw "Flutter-OH not found. Set FLUTTER_OH_ROOT to your oh-3.41.9-release checkout."
}

function Get-HarmonyOhosDepsRoot {
  if ($env:OHOS_DEPS_ROOT) { return $env:OHOS_DEPS_ROOT }
  return "F:\ohos-deps-341"
}

function Get-HarmonyHosSdkDir {
  if ($env:HOS_SDK_HOME -and (Test-Path (Join-Path $env:HOS_SDK_HOME "sdk-pkg.json"))) {
    return $env:HOS_SDK_HOME
  }
  if ($env:DEVECO_SDK_HOME -and (Test-Path (Join-Path $env:DEVECO_SDK_HOME "sdk-pkg.json"))) {
    return $env:DEVECO_SDK_HOME
  }
  foreach ($cand in @(
      "F:\harmony-sdk\default",
      (Join-Path (Get-HarmonyDevecoRoot) "sdk\default")
    )) {
    if (Test-Path (Join-Path $cand "sdk-pkg.json")) { return $cand }
  }
  throw "HarmonyOS SDK not found (sdk-pkg.json). Set HOS_SDK_HOME."
}
