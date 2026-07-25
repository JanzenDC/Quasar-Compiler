$ErrorActionPreference = 'SilentlyContinue'

function Get-ConsoleWidth {
    try {
        $w = [Console]::WindowWidth
        if ($w -ge 40) { return $w }
    } catch {}
    return 80
}

function Write-Centered {
    param(
        [string]$Text,
        [int]$ColorCode = 0,
        [switch]$Dim
    )
    $width = Get-ConsoleWidth
    $len = $Text.Length
    $pad = [Math]::Max(0, [Math]::Floor(($width - $len) / 2))
    $line = (' ' * $pad) + $Text
    if ($ColorCode -gt 0) {
        Write-Host ("$([char]27)[${ColorCode}m$line$([char]27)[0m")
    } elseif ($Dim) {
        Write-Host ("$([char]27)[90m$line$([char]27)[0m")
    } else {
        Write-Host $line
    }
}

$path = Join-Path $PSScriptRoot 'build-capacitor-android-banner.txt'
$consoleWidth = Get-ConsoleWidth
Write-Host ''

# Quasar-like cyan -> blue -> magenta -> red
$colors = @(96, 94, 95, 35, 91, 31)

if (Test-Path -LiteralPath $path) {
    $lines = @(Get-Content -LiteralPath $path -Encoding Default | ForEach-Object { $_.TrimEnd() })
    $blockWidth = ($lines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
    if (-not $blockWidth) { $blockWidth = 0 }
    $blockPad = [Math]::Max(0, [Math]::Floor(($consoleWidth - $blockWidth) / 2))
    $left = ' ' * $blockPad

    $i = 0
    foreach ($raw in $lines) {
        if ($raw.Trim().Length -eq 0) {
            Write-Host ''
            continue
        }
        # Pad right so relative letter alignment stays correct inside the block
        $padded = $raw.PadRight($blockWidth)
        $code = $colors[$i % $colors.Count]
        Write-Host ("$([char]27)[${code}m$left$padded$([char]27)[0m")
        $i++
    }
} else {
    Write-Centered -Text 'CAPACITOR' -ColorCode 96
}

Write-Host ''
Write-Centered -Text 'Android APK Builder  -  no Android Studio' -Dim
Write-Centered -Text 'Powered by Nexus IT Solutions Inc.' -ColorCode 96
Write-Host ''
