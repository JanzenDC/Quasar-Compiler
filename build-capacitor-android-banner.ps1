$ErrorActionPreference = 'SilentlyContinue'
$path = Join-Path $PSScriptRoot 'build-capacitor-android-banner.txt'
if (-not (Test-Path -LiteralPath $path)) {
    Write-Host '  QUASAR CAPACITOR'
    exit 0
}

# Quasar-like cyan -> blue -> magenta -> red
$colors = @(96, 94, 95, 35, 91, 31, 90)
$i = 0
Get-Content -LiteralPath $path -Encoding UTF8 | ForEach-Object {
    $code = $colors[$i % $colors.Count]
    Write-Host ("$([char]27)[${code}m$_$([char]27)[0m")
    $i++
}
