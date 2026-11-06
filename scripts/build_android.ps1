# ==============================================================================
# Script Otomatis Pembuatan APK Cineva (Ponsel & Android TV)
# ==============================================================================
# Cara menjalankan:
#   .\scripts\build_android.ps1           # Build semua varian + Obfuscate (Default)
#   .\scripts\build_android.ps1 -Tv       # Khusus Android TV (32-bit ARM super ringan + Obfuscate)
#   .\scripts\build_android.ps1 -Mobile   # Khusus Ponsel Android Modern (64-bit ARM + Obfuscate)
#   .\scripts\build_android.ps1 -All      # Build semua (arm64, armeabi-v7a, x86_64, universal, & android-tv)
#   .\scripts\build_android.ps1 -NoObfuscate # Nonaktifkan obfuscation (untuk debug simbol)
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
    [string]$Target = "all",

    [Parameter()]
    [switch]$NoObfuscate
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
    $appVersion = "1.1.5"
}
Write-Host "[1/3] Versi aplikasi terdeteksi: v$appVersion" -ForegroundColor Green

# Tentukan Mode Target
$mode = "all"
if ($Tv.IsPresent -or $Target -eq "tv") {
    $mode = "tv"
} elseif ($Mobile.IsPresent -or $Target -eq "mobile") {
    $mode = "mobile"
}

Write-Host "[2/3] Mengonfigurasi parameter kompilasi (Target: $mode)..." -ForegroundColor Cyan

$apkOutputDir = "build\app\outputs\flutter-apk"
$symbolsDir = "build\app\outputs\symbols"

$flutterArgs = @("build", "apk", "--release", "--split-per-abi")

switch ($mode) {
    "tv" {
        Write-Host "[-] Menyiapkan target khusus Android TV (32-bit ARM, hemat penyimpanan & ringan)..." -ForegroundColor Yellow
        $flutterArgs += @("--target-platform", "android-arm")
    }
    "mobile" {
        Write-Host "[-] Menyiapkan target khusus Ponsel Android Modern (64-bit ARM)..." -ForegroundColor Yellow
        $flutterArgs += @("--target-platform", "android-arm64")
    }
    default {
        Write-Host "[-] Menyiapkan seluruh varian arsitektur CPU (--split-per-abi)..." -ForegroundColor Yellow
    }
}

# Konfigurasi Obfuscation
if (-not $NoObfuscate) {
    if (-not (Test-Path $symbolsDir)) {
        New-Item -ItemType Directory -Force -Path $symbolsDir | Out-Null
    }
    $flutterArgs += @("--obfuscate", "--split-debug-info=$symbolsDir")
    Write-Host "[-] Proteksi Kode: AKTIF (--release, --obfuscate, & symbols diekspor ke $symbolsDir)" -ForegroundColor Magenta
} else {
    Write-Host "[-] Proteksi Kode: NONAKTIF (--no-obfuscate)" -ForegroundColor DarkGray
}

Write-Host "[-] Menjalankan perintah: flutter $($flutterArgs -join ' ')" -ForegroundColor DarkCyan

& flutter $flutterArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Gagal melakukan build Flutter APK."
}

# Pastikan file Cineva_v{ver}-android-tv.apk tercipta dari armeabi-v7a jika ada
$srcArmV7 = Join-Path $apkOutputDir "app-armeabi-v7a-release.apk"
if (-not (Test-Path $srcArmV7)) {
    $srcArmV7 = Join-Path $apkOutputDir "Cineva_v$appVersion-armeabi-v7a.apk"
}
if (Test-Path $srcArmV7) {
    $tvDest = Join-Path $apkOutputDir "Cineva_v$appVersion-android-tv.apk"
    Copy-Item -Path $srcArmV7 -Destination $tvDest -Force
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
    if (-not $NoObfuscate) {
        Write-Host " Simbol Obfuscation: $symbolsDir" -ForegroundColor DarkCyan
    }
    Write-Host " Lokasi direktori APK: $apkOutputDir" -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green
} else {
    Write-Warning "Direktori output $apkOutputDir tidak ditemukan."
}
