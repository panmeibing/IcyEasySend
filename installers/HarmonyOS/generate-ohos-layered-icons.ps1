# Regenerates HarmonyOS icons. Two different products — do not mix them:
#
# 1) Store / desktop layered icons (cloud-test rules):
#    - foreground.png + background.png, both 1024x1024
#    - full-bleed square (no self-rounded corners, no inner padding)
#    - referenced via layered_image / app_layered_image
#    - source: lib/images/icon_1024x1024.png composited onto a full gradient square
#
# 2) Launch splash only (startWindowIcon):
#    - start_icon.png — circular logo on transparent canvas (may look smaller)
#    - NEVER use this for AppScope/entry layered icon fields
#    - source: lib/images/icon_256x256.png (already has alpha outside the circle)
#
# Do NOT use lib/images/icon.jpg for either (no alpha; pre-cut circle + white margin).
#
# Run from repo root, then rebuild HAP / DevEco Run.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$SrcLayered = Join-Path $RepoRoot "lib\images\icon_1024x1024.png"
$SrcSplash = Join-Path $RepoRoot "lib\images\icon_256x256.png"
if (-not (Test-Path $SrcLayered)) { throw "Missing $SrcLayered" }
if (-not (Test-Path $SrcSplash)) { throw "Missing $SrcSplash" }

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

# --- 1) Layered 1024 store icons (full-bleed) ---
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
# Keep entry icon.png as full-bleed fallback (ohosTest etc.); NOT used for startWindowIcon.
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

# --- 2) Splash start_icon (transparent, intentionally smaller) ---
$splashSrc = [System.Drawing.Bitmap]::FromFile($SrcSplash)
$outSize = 512
$logoSize = 288
$canvas = New-Object System.Drawing.Bitmap $outSize, $outSize
$canvas.MakeTransparent()
$gs = [System.Drawing.Graphics]::FromImage($canvas)
$gs.Clear([System.Drawing.Color]::Transparent)
$gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gs.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$pad = [int](($outSize - $logoSize) / 2)
$gs.DrawImage($splashSrc, $pad, $pad, $logoSize, $logoSize)
$gs.Dispose()
$splashSrc.Dispose()

foreach ($d in @(
    (Join-Path $RepoRoot "ohos\entry\src\main\resources\base\media"),
    (Join-Path $PSScriptRoot "native\media")
  )) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  $canvas.Save((Join-Path $d "start_icon.png"), [System.Drawing.Imaging.ImageFormat]::Png)
}
$canvas.Dispose()

Write-Host "OK: layered 1024 foreground/background (store) + start_icon.png (splash only)."
Write-Host "Confirm module.json5: icon=`$media:layered_image, startWindowIcon=`$media:start_icon"
