param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$releaseDir = Join-Path $root "build\windows\x64\runner\Release"
$outDir = Join-Path $PSScriptRoot "Output"
$zipName = "IcyEasySend-windows-v$Version-portable.zip"
$zipPath = Join-Path $outDir $zipName

if (-not (Test-Path (Join-Path $releaseDir "IcyEasySend.exe"))) {
    Write-Error "Release build not found. Run: flutter build windows --release"
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path (Join-Path $releaseDir "*") -DestinationPath $zipPath -Force
Write-Host "Built: $zipPath"
