# ==============================================================================
# Script Otomatis Pembuatan APK Cineva (Ponsel & Android TV)
# ==============================================================================
# Cara menjalankan:
#   .\scripts\build_android.ps1           # Build semua varian (Default)
#   .\scripts\build_android.ps1 -Tv       # Khusus Android TV (32-bit ARM super ringan)
#   .\scripts\build_android.ps1 -Mobile   # Khusus Ponsel Android Modern (64-bit ARM)
#   .\scripts\build_android.ps1 -All      # Build semua (arm64, armeabi-v7a, x86_64, universal, & android-tv)
# ==============================================================================

[CmdletBinding(DefaultParameterSetName = "Default")]
param(
    [Parameter(ParameterSetName = "Tv")]
    [switch]$Tv,

    [Parameter(ParameterSetName = "Mobile")]
    [switch]$Mobile,

    [Parameter(ParameterSetName = "All")]
    [switch]$All,

    [Parameter(ParameterSetName = "TargetParam")]
    [ValidateSet("tv", "mobile", "all")]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Cineva Android & Android TV Build Automation" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Baca Versi Aplikasi dari pubspec.yaml
$pubspecPath = "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    Write-Error "pubspec.yaml tidak ditemukan di direktori saat ini."
}

$versionLine = Get-Content $pubspecPath | Where-Object { $_ -match "^version:\s*([0-9]+\.[0-9]+\.[0-9]+)" }
if ($versionLine -match "([0-9]+\.[0-9]+\.[0-9]+)") {
    $appVersion = $Matches[1]
} else {
    $appVersion = "1.1.4"
}
Write-Host "[1/3] Versi aplikasi terdeteksi: v$appVersion" -ForegroundColor Green

# Tentukan Mode Target
$mode = "all"
if ($Tv.IsPresent -or $Target -eq "tv") {
    $mode = "tv"
} elseif ($Mobile.IsPresent -or $Target -eq "mobile") {
    $mode = "mobile"
}

Write-Host "[2/3] Memulai kompilasi Flutter APK (Target: $mode)..." -ForegroundColor Cyan

$apkOutputDir = "build\app\outputs\flutter-apk"

switch ($mode) {
    "tv" {
        Write-Host "[-] Mengompilasi build khusus Android TV (32-bit ARM, hemat penyimpanan & ringan)..." -ForegroundColor Yellow
        # Build khusus 32-bit ARM (kompatibel dengan 99.9% Android TV / Smart TV / TV Stick)
        flutter build apk --release --target-platform android-arm --split-per-abi
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Gagal melakukan build Flutter APK untuk Android TV."
        }
        
        # Pastikan file Cineva_v{ver}-android-tv.apk tercipta dari armeabi-v7a
        $srcArmV7 = Join-Path $apkOutputDir "app-armeabi-v7a-release.apk"
        if (-not (Test-Path $srcArmV7)) {
            $srcArmV7 = Join-Path $apkOutputDir "Cineva_v$appVersion-armeabi-v7a.apk"
        }
        if (Test-Path $srcArmV7) {
            $tvDest = Join-Path $apkOutputDir "Cineva_v$appVersion-android-tv.apk"
            Copy-Item -Path $srcArmV7 -Destination $tvDest -Force
        }
    }
    "mobile" {
        Write-Host "[-] Mengompilasi build khusus Ponsel Android Modern (64-bit ARM)..." -ForegroundColor Yellow
        flutter build apk --release --target-platform android-arm64 --split-per-abi
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Gagal melakukan build Flutter APK untuk Ponsel."
        }
    }
    default {
        Write-Host "[-] Mengompilasi seluruh varian dengan --split-per-abi..." -ForegroundColor Yellow
        flutter build apk --release --split-per-abi
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Gagal melakukan build Flutter APK release."
        }
        
        # Pastikan file Cineva_v{ver}-android-tv.apk juga siap
        $srcArmV7 = Join-Path $apkOutputDir "app-armeabi-v7a-release.apk"
        if (-not (Test-Path $srcArmV7)) {
            $srcArmV7 = Join-Path $apkOutputDir "Cineva_v$appVersion-armeabi-v7a.apk"
        }
        if (Test-Path $srcArmV7) {
            $tvDest = Join-Path $apkOutputDir "Cineva_v$appVersion-android-tv.apk"
            Copy-Item -Path $srcArmV7 -Destination $tvDest -Force
        }
    }
}

Write-Host "[3/3] Memeriksa artefak APK yang dihasilkan..." -ForegroundColor Cyan

if (Test-Path $apkOutputDir) {
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host " SUKSES! Artefak APK Cineva berhasil dibuat:" -ForegroundColor Green
    
    $apks = Get-ChildItem -Path $apkOutputDir -Filter "Cineva_v*.apk"
    foreach ($apk in $apks) {
        $sizeMB = [math]::Round($apk.Length / 1MB, 2)
        if ($apk.Name -like "*android-tv*") {
            Write-Host " -> [Android TV] $($apk.Name) (${sizeMB} MB) [RINGAN & OPTIMAL UNTUK TV]" -ForegroundColor Magenta
        } else {
            Write-Host " -> $($apk.Name) (${sizeMB} MB)" -ForegroundColor White
        }
    }
    Write-Host " Lokasi direktori: $apkOutputDir" -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green
} else {
    Write-Warning "Direktori output $apkOutputDir tidak ditemukan."
}
