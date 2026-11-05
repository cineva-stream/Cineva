# ==============================================================================
# Script Otomatis Pembuatan Setup Installer Cineva Windows
# ==============================================================================
# Cara menjalankan:
#   powershell -ExecutionPolicy Bypass -File scripts\build_windows_setup.ps1
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Cineva Windows Setup Installer Builder" -ForegroundColor Cyan
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
Write-Host "[1/4] Versi aplikasi terdeteksi: v$appVersion" -ForegroundColor Green

# 2. Cari Kompiler Inno Setup (iscc.exe)
$isccPath = Get-Command "iscc" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $isccPath) {
    $standardPaths = @(
        "C:\Program Files (x86)\Inno Setup 6\iscc.exe",
        "C:\Program Files\Inno Setup 6\iscc.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\iscc.exe"
    )
    foreach ($path in $standardPaths) {
        if (Test-Path $path) {
            $isccPath = $path
            break
        }
    }
}

if (-not $isccPath) {
    Write-Host "[PERINGATAN] Inno Setup 6 tidak terdeteksi di sistem!" -ForegroundColor Yellow
    Write-Host "Silakan pasang Inno Setup 6 melalui winget dengan perintah berikut di PowerShell:" -ForegroundColor Yellow
    Write-Host "   winget install JRSoftware.InnoSetup" -ForegroundColor White
    Write-Host "Atau unduh manual dari: https://jrsoftware.org/isdl.php" -ForegroundColor White
    exit 1
}
Write-Host "[2/4] Kompiler Inno Setup ditemukan di: $isccPath" -ForegroundColor Green

# 2.5 Sinkronisasi Ikon Multi-Resolusi Windows (.ico) dari cineva_icon.png
Write-Host "[-] Menghasilkan ikon native multi-resolusi Windows (BMP+PNG)..." -ForegroundColor Cyan
python scripts\generate_windows_icon.py

# 3. Jalankan Flutter Build Windows Release
Write-Host "[3/4] Melakukan kompilasi Flutter Windows Release..." -ForegroundColor Cyan
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Gagal melakukan build Flutter Windows release."
}

# 4. Kompilasi Installer .exe dengan Inno Setup
Write-Host "[4/4] Mengemas installer tunggal Cineva_setup_v$appVersion.exe..." -ForegroundColor Cyan
$issScript = "windows\installer\cineva_installer.iss"
if (-not (Test-Path $issScript)) {
    Write-Error "Script installer $issScript tidak ditemukan."
}

& "$isccPath" "/DMyAppVersion=$appVersion" "$issScript"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Gagal mengompilasi installer Inno Setup."
}

$outputExe = "build\installer\Cineva_setup_v$appVersion.exe"
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " SUKSES! Installer Cineva berhasil dibuat:" -ForegroundColor Green
Write-Host " Lokasi file: $outputExe" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green

