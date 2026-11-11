; ==============================================================================
; Inno Setup Script untuk Cineva Windows Installer
; Menghasilkan 1 file tunggal: Cineva_setup_v{versi}.exe
; ==============================================================================

#ifndef MyAppVersion
  #define MyAppVersion "1.1.8"
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
LicenseFile=terms_and_conditions_id.rtf

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
Name: "indonesian"; MessagesFile: "Indonesian.isl"; LicenseFile: "terms_and_conditions_id.rtf"
Name: "english"; MessagesFile: "compiler:Default.isl"; LicenseFile: "terms_and_conditions_en.rtf"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Seluruh berkas keluaran dari 'flutter build windows --release'
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Catatan: Jangan gunakan "Flags: ignoreversion" pada berkas sistem bersama

[Icons]
; Pintasan di Start Menu
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"; Parameters: "/SILENT"
; Pintasan opsional di Desktop
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Opsi menjalankan aplikasi setelah proses setup selesai
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[CustomMessages]
indonesian.UninstallTitle=Pelepasan Cineva
indonesian.UninstallPrompt=Apakah Anda yakin ingin menghapus Cineva dan semua komponennya dari komputer Anda?
indonesian.KeepMyData=Simpan data saya
indonesian.BtnYes=&Ya
indonesian.BtnNo=&Tidak

english.UninstallTitle=Cineva Uninstall
english.UninstallPrompt=Are you sure you want to completely remove Cineva and all of its components from your computer?
english.KeepMyData=Keep my data
english.BtnYes=&Yes
english.BtnNo=&No

[Code]
var
  KeepDataChecked: Boolean;

function InitializeUninstall(): Boolean;
var
  CustomForm: TSetupForm;
  PromptLabel: TNewStaticText;
  KeepDataCheckBox: TNewCheckBox;
  YesButton: TNewButton;
  NoButton: TNewButton;
begin
  Result := False;
  KeepDataChecked := False;

  // Hanya lewati jika dijalankan dengan parameter /VERYSILENT (otomasi tanpa antarmuka)
  if Pos('/VERYSILENT', UpperCase(GetCmdTail)) > 0 then
  begin
    Result := True;
    Exit;
  end;

  CustomForm := CreateCustomForm(ScaleX(440), ScaleY(190), False, True);
  try
    CustomForm.Caption := CustomMessage('UninstallTitle');
    CustomForm.Position := poScreenCenter;

    PromptLabel := TNewStaticText.Create(CustomForm);
    PromptLabel.Parent := CustomForm;
    PromptLabel.Left := ScaleX(24);
    PromptLabel.Top := ScaleY(22);
    PromptLabel.Width := CustomForm.ClientWidth - ScaleX(48);
    PromptLabel.Height := ScaleY(55);
    PromptLabel.WordWrap := True;
    PromptLabel.Caption := CustomMessage('UninstallPrompt');

    KeepDataCheckBox := TNewCheckBox.Create(CustomForm);
    KeepDataCheckBox.Parent := CustomForm;
    KeepDataCheckBox.Left := ScaleX(24);
    KeepDataCheckBox.Top := ScaleY(90);
    KeepDataCheckBox.Width := CustomForm.ClientWidth - ScaleX(48);
    KeepDataCheckBox.Height := ScaleY(22);
    KeepDataCheckBox.Caption := CustomMessage('KeepMyData');
    KeepDataCheckBox.Checked := False;

    YesButton := TNewButton.Create(CustomForm);
    YesButton.Parent := CustomForm;
    YesButton.Left := CustomForm.ClientWidth - ScaleX(185);
    YesButton.Top := CustomForm.ClientHeight - ScaleY(44);
    YesButton.Width := ScaleX(75);
    YesButton.Height := ScaleY(25);
    YesButton.Caption := CustomMessage('BtnYes');
    YesButton.ModalResult := mrOk;
    YesButton.Default := True;

    NoButton := TNewButton.Create(CustomForm);
    NoButton.Parent := CustomForm;
    NoButton.Left := CustomForm.ClientWidth - ScaleX(98);
    NoButton.Top := CustomForm.ClientHeight - ScaleY(44);
    NoButton.Width := ScaleX(75);
    NoButton.Height := ScaleY(25);
    NoButton.Caption := CustomMessage('BtnNo');
    NoButton.ModalResult := mrCancel;
    NoButton.Cancel := True;

    if CustomForm.ShowModal = mrOk then
    begin
      KeepDataChecked := KeepDataCheckBox.Checked;
      Result := True;
    end;
  finally
    CustomForm.Free;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  DocsPath: String;
  FindRec: TFindRec;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    if not KeepDataChecked then
    begin
      DocsPath := ExpandConstant('{userdocs}');

      // Hapus basis data Hive Cineva di Documents
      DeleteFile(DocsPath + '\settings.hive');
      DeleteFile(DocsPath + '\settings.lock');
      DeleteFile(DocsPath + '\watchlist.hive');
      DeleteFile(DocsPath + '\watchlist.lock');
      DeleteFile(DocsPath + '\watch_history.hive');
      DeleteFile(DocsPath + '\watch_history.lock');
      DeleteFile(DocsPath + '\cineva_downloads.hive');
      DeleteFile(DocsPath + '\cineva_downloads.lock');

      // Hapus berkas avatar tersinkronisasi di Documents
      if FindFirst(DocsPath + '\synced_avatar_*.*', FindRec) then
      begin
        try
          repeat
            DeleteFile(DocsPath + '\' + FindRec.Name);
          until not FindNext(FindRec);
        finally
          FindClose(FindRec);
        end;
      end;

      if FindFirst(DocsPath + '\avatar_*.*', FindRec) then
      begin
        try
          repeat
            DeleteFile(DocsPath + '\' + FindRec.Name);
          until not FindNext(FindRec);
        finally
          FindClose(FindRec);
        end;
      end;

      // Hapus cache dan data aplikasi di AppData & LocalAppData
      DelTree(ExpandConstant('{userappdata}\com.primadev\cineva'), True, True, True);
      DelTree(ExpandConstant('{localappdata}\com.primadev\cineva'), True, True, True);
      DelTree(ExpandConstant('{userappdata}\Cineva'), True, True, True);
      DelTree(ExpandConstant('{localappdata}\Cineva'), True, True, True);
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  UninstallPath: String;
  UninstallStr: String;
begin
  if CurStep = ssPostInstall then
  begin
    UninstallPath := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\' + ExpandConstant('{#SetupSetting("AppId")}') + '_is1';

    if RegQueryStringValue(HKLM, UninstallPath, 'UninstallString', UninstallStr) then
    begin
      if Pos('/SILENT', UpperCase(UninstallStr)) = 0 then
      begin
        RegWriteStringValue(HKLM, UninstallPath, 'UninstallString', UninstallStr + ' /SILENT');
      end;
    end;

    if RegQueryStringValue(HKCU, UninstallPath, 'UninstallString', UninstallStr) then
    begin
      if Pos('/SILENT', UpperCase(UninstallStr)) = 0 then
      begin
        RegWriteStringValue(HKCU, UninstallPath, 'UninstallString', UninstallStr + ' /SILENT');
      end;
    end;
  end;
end;

