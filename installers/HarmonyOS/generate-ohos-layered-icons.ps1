# Regenerates HarmonyOS layered icons for store / launcher (ability icon).
#
# Layered icons (AppGallery + launcher + ability icon):
#    - foreground.png + background.png, both 1024x1024
#    - full-bleed square (no self-rounded corners, no inner padding)
#    - referenced via layered_image / app_layered_image
#    - source: lib/images/icon_1024x1024.png composited onto a full gradient square
#
# Also refreshes flat icon.png (ohosTest / fallback) from the same foreground.
#
# Does NOT touch start_icon.png — that is the launch splash art (circular on
# white). Keep startWindowIcon = $media:start_icon in module.json5.
#
# Do NOT use lib/images/icon.jpg (no alpha; pre-cut circle + white margin).
#
# Run from repo root, then rebuild HAP / DevEco Run.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$SrcLayered = Join-Path $RepoRoot "lib\images\icon_1024x1024.png"
if (-not (Test-Path $SrcLayered)) { throw "Missing $SrcLayered" }

function New-GradientBitmap([int]$w, [int]$h) {
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  for ($y = 0; $y -lt $h; $y++) {
    $t = $y / [double]($h - 1)
    $r = [int](94 + (70 - 94) * $t)
    $g = [int](214 + (137 - 214) * $t)
    $b = [int](251 + (249 - 251) * $t)
    $c = [System.Drawing.Color]::FromArgb(255, $r, $g, $b)
    for ($x = 0; $x -lt $w; $x++) { $bmp.SetPixel($x, $y, $c) }
  }
  return $bmp
}

$src = [System.Drawing.Bitmap]::FromFile($SrcLayered)
if ($src.Width -ne 1024 -or $src.Height -ne 1024) {
  $src.Dispose()
  throw "Layered source must be 1024x1024 px"
}

$background = New-GradientBitmap 1024 1024
$foreground = New-GradientBitmap 1024 1024
$g = [System.Drawing.Graphics]::FromImage($foreground)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($src, 0, 0, 1024, 1024)
$g.Dispose()
$src.Dispose()

$dirs = @(
  (Join-Path $RepoRoot "ohos\AppScope\resources\base\media"),
  (Join-Path $RepoRoot "ohos\entry\src\main\resources\base\media"),
  (Join-Path $PSScriptRoot "native\media")
)
foreach ($d in $dirs) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  $background.Save((Join-Path $d "background.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $foreground.Save((Join-Path $d "foreground.png"), [System.Drawing.Imaging.ImageFormat]::Png)
}

$foreground.Save(
  (Join-Path $RepoRoot "ohos\AppScope\resources\base\media\app_icon.png"),
  [System.Drawing.Imaging.ImageFormat]::Png
)
# Flat full-bleed used by ohosTest / fallback (not the launch splash).
$foreground.Save(
  (Join-Path $RepoRoot "ohos\entry\src\main\resources\base\media\icon.png"),
  [System.Drawing.Imaging.ImageFormat]::Png
)
$foreground.Save(
  (Join-Path $PSScriptRoot "native\media\foreground.png"),
  [System.Drawing.Imaging.ImageFormat]::Png
)
$background.Save(
  (Join-Path $PSScriptRoot "native\media\background.png"),
  [System.Drawing.Imaging.ImageFormat]::Png
)

$background.Dispose()
$foreground.Dispose()

Write-Host "OK: layered 1024 foreground/background + icon.png. start_icon.png left unchanged."
Write-Host "Confirm module.json5: icon=`$media:layered_image, startWindowIcon=`$media:start_icon"
