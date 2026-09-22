# Ensure Flutter-OH reports a real version after shallow clone.
# Usage: called by activate / pub-get / flutter-oh wrappers when needed.

$FlutterOhRoot = "F:\flutter_flutter_ohos_341"
$VersionFile = Join-Path $FlutterOhRoot "version"
$JsonFile = Join-Path $FlutterOhRoot "bin\cache\flutter.version.json"

if (-not (Test-Path $VersionFile)) {
    Set-Content -Path $VersionFile -Value "3.41.9" -NoNewline
}

if (Test-Path $JsonFile) {
    $raw = Get-Content $JsonFile -Raw
    if ($raw -match '0\.0\.0-unknown') {
        $json = @{
            channel               = "oh-3.41.9-release"
            frameworkVersion      = "3.41.9"
            flutterVersion        = "3.41.9"
            repositoryUrl         = "https://gitcode.com/CPF-Flutter/flutter_flutter.git"
            frameworkRevision     = "e9d2d057cc"
            frameworkCommitDate   = "2026-09-18 16:29:58 +0800"
            engineRevision        = "42d3d75a56efe1a2e9902f52dc8006099c45d937"
            engineCommitDate      = "2026-04-28 17:31:55.000Z"
            engineContentHash     = "9161402dc0e134b3fb5adee5046b6e84b1a5e1c1"
            engineBuildDate       = "2026-04-29 03:37:18.442"
            dartSdkVersion        = "3.11.5"
            devToolsVersion       = "2.54.1"
        } | ConvertTo-Json
        Set-Content -Path $JsonFile -Value $json -Encoding utf8
    }
}
