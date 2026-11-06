<#
.SYNOPSIS
    Skrip penandatanganan digital (Code Signing) untuk Cineva di Windows.
    Menghilangkan peringatan "Unknown Publisher" dan membubuhkan tanda tangan resmi.

.DESCRIPTION
    Skrip ini mendukung 2 mode:
    1. Self-Signed Certificate (Lokal / Development):
       Membuat sertifikat Code Signing lokal "Cineva Stream", mengekspor .pfx dan .cer,
       serta menandatangani cineva.exe dan Cineva_setup_v1.1.4.exe.
    2. Official CA Certificate (Produksi):
       Jika Anda memiliki sertifikat dari Sectigo / DigiCert / GlobalSign (.pfx),
       Anda dapat menyediakannya untuk tanda tangan publik tanpa peringatan SmartScreen.

.EXAMPLE
    .\scripts\sign_windows_installer.ps1 -CreateSelfSigned
    .\scripts\sign_windows_installer.ps1 -CertPath "windows\certs\cineva_cert.pfx" -CertPassword "123456"
#>

param(
    [switch]$CreateSelfSigned,
    [string]$CertPath = "",
    [string]$CertPassword = "cineva_stream_secure_dev",
    [string]$TargetFile = "build\installer\Cineva_setup_v1.1.4.exe"
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   CINEVA WINDOWS CODE SIGNING TOOL" -ForegroundColor Yellow
Write-Host "========================================================`n" -ForegroundColor Cyan

# 1. Temukan SignTool.exe di sistem
$signtoolPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\signtool.exe"
)

$signtool = $null
foreach ($path in $signtoolPaths) {
    $found = Get-Item $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $signtool = $found.FullName
        break
    }
}

if (-not $signtool) {
    Write-Error "SignTool.exe tidak ditemukan. Harap pastikan Windows 10/11 SDK terpasang."
}
Write-Host "[OK] Menggunakan SignTool: $signtool" -ForegroundColor Green

# 2. Buat atau muat sertifikat
$certDir = "windows\certs"
if (-not (Test-Path $certDir)) {
    New-Item -ItemType Directory -Path $certDir -Force | Out-Null
}

$defaultPfx = Join-Path $certDir "cineva_dev.pfx"
$defaultCer = Join-Path $certDir "cineva_dev.cer"

if ($CreateSelfSigned -or (-not (Test-Path $defaultPfx) -and [string]::IsNullOrEmpty($CertPath))) {
    Write-Host "[1/3] Membuat Self-Signed Code Signing Certificate untuk Cineva Stream..." -ForegroundColor Cyan
    
    $securePassword = ConvertTo-SecureString -String $CertPassword -AsPlainText -Force
    
    $cert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject "CN=Cineva Stream, O=Cineva, OU=Streaming, E=cineva.dev@gmail.com" `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -NotAfter (Get-Date).AddYears(5) `
        -FriendlyName "Cineva Stream Official Developer Certificate"

    # Ekspor PFX (Private + Public)
    Export-PfxCertificate -Cert $cert -FilePath $defaultPfx -Password $securePassword | Out-Null
    # Ekspor CER (Public only untuk diimpor ke Trusted Root di PC klien)
    Export-Certificate -Cert $cert -FilePath $defaultCer | Out-Null

    Write-Host "  -> Berhasil membuat sertifikat PFX: $defaultPfx" -ForegroundColor Green
    Write-Host "  -> Berhasil mengekspor sertifikat CER: $defaultCer" -ForegroundColor Green
    $CertPath = $defaultPfx
} elseif ([string]::IsNullOrEmpty($CertPath)) {
    $CertPath = $defaultPfx
}

if (-not (Test-Path $CertPath)) {
    Write-Error "Berkas sertifikat tidak ditemukan di $CertPath"
}

# 3. Target file yang akan ditandatangani
$filesToSign = @()
if (Test-Path "build\windows\x64\runner\Release\cineva.exe") {
    $filesToSign += "build\windows\x64\runner\Release\cineva.exe"
}
if (Test-Path $TargetFile) {
    $filesToSign += $TargetFile
}

if ($filesToSign.Count -eq 0) {
    Write-Warning "Tidak ada berkas target yang ditemukan untuk ditandatangani."
    Exit 0
}

Write-Host "`n[2/3] Menandatangani berkas dengan Authenticode SHA-256 + RFC 3161 Timestamp..." -ForegroundColor Cyan

foreach ($file in $filesToSign) {
    Write-Host "  -> Menandatangani $file ..." -ForegroundColor Yellow
    & $signtool sign `
        /fd SHA256 `
        /f $CertPath `
        /p $CertPassword `
        /tr "http://timestamp.digicert.com" `
        /td SHA256 `
        /d "Cineva Stream" `
        /du "https://cineva-stream.github.io/cineva-web" `
        $file

    if ($LASTEXITCODE -eq 0) {
        Write-Host "     [SUKSES] Berhasil ditandatangani!" -ForegroundColor Green
    } else {
        Write-Warning "     Gagal menandatangani $file (Exit code: $LASTEXITCODE)"
    }
}

Write-Host "`n[3/3] Memverifikasi tanda tangan digital..." -ForegroundColor Cyan
foreach ($file in $filesToSign) {
    & $signtool verify /pa /v $file
}

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "   PENANDATANGANAN SELESAI!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Agar sertifikat self-signed ini dikenali sebagai 'Verified Publisher' di komputer Anda:" -ForegroundColor Yellow
Write-Host "1. Klik dua kali berkas: $defaultCer"
Write-Host "2. Klik 'Install Certificate...'"
Write-Host "3. Pilih 'Local Machine' atau 'Current User' -> Next"
Write-Host "4. Pilih 'Place all certificates in the following store' -> Browse"
Write-Host "5. Pilih 'Trusted Root Certification Authorities' -> OK -> Finish`n"

