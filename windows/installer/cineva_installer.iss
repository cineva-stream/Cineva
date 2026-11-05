; ==============================================================================
; Inno Setup Script untuk Cineva Windows Installer
; Menghasilkan 1 file tunggal: Cineva_setup_v{versi}.exe
; ==============================================================================

#ifndef MyAppVersion
  #define MyAppVersion "1.1.4"
#endif

#define MyAppName "Cineva"
#define MyAppPublisher "Cineva Stream"
#define MyAppURL "https://cineva-stream.github.io/cineva-web"
#define MyAppExeName "cineva.exe"

[Setup]
; Identifikasi unik aplikasi (GUID baru khusus untuk Cineva)
AppId={{5D8E6F34-87A2-4CFB-9B21-A9D4E76A3D19}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} v{#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Direktori default instalasi (mendukung per-user atau per-machine otomatis)
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes

; Syarat dan Ketentuan (Halaman LEGAL) sebelum instalasi dimulai
LicenseFile=terms_and_conditions.txt

; Ikon installer dan ikon uninstaller
SetupIconFile=app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

; Lokasi dan nama berkas installer keluaran
OutputDir=..\..\build\installer
OutputBaseFilename=Cineva_setup_v{#MyAppVersion}

; Gaya Wizard modern & kompresi solid tingkat tinggi (LZMA2)
WizardStyle=modern
WizardSizePercent=100
Compression=lzma2/max
SolidCompression=yes

; Hak akses instalasi fleksibel (tidak wajib Administrator jika diinstal per-user)
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "indonesian"; MessagesFile: "Indonesian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Seluruh berkas keluaran dari 'flutter build windows --release'
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Catatan: Jangan gunakan "Flags: ignoreversion" pada berkas sistem bersama

[Icons]
; Pintasan di Start Menu
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
; Pintasan opsional di Desktop
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Opsi menjalankan aplikasi setelah proses setup selesai
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

