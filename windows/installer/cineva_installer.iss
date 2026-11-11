; ==============================================================================
; Inno Setup Script untuk Cineva Windows Installer (Full Custom Dark Cinema UI)
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
; Identifikasi unik aplikasi (GUID khusus untuk Cineva)
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
DisableProgramGroupPage=yes
DisableWelcomePage=yes
AllowNoIcons=yes

; Syarat dan Ketentuan (Halaman LEGAL) sebelum instalasi dimulai
LicenseFile=terms_and_conditions_id.rtf

; Ikon installer dan ikon uninstaller
SetupIconFile=app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

; Lokasi dan nama berkas installer keluaran
OutputDir=..\..\build\installer
OutputBaseFilename=Cineva_setup_v{#MyAppVersion}

; Gaya Wizard Modern Dark Mode & Palet Obsidian (#0E0E14)
WizardStyle=modern dark
WizardBackColor=#0E0E14
WizardBackColorDynamicDark=#0E0E14
WizardSizePercent=115,115
Compression=lzma2/max
SolidCompression=yes

; Hak akses instalasi fleksibel (tidak wajib Administrator jika diinstal per-user)
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "indonesian"; MessagesFile: "Indonesian.isl"; LicenseFile: "terms_and_conditions_id.rtf"
Name: "english"; MessagesFile: "compiler:Default.isl"; LicenseFile: "terms_and_conditions_en.rtf"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
; Aset Visual Header Animasi Poster & Logo Brand (hanya diekstrak ke {tmp} saat setup)
Source: "marquee_strip.bmp"; Flags: dontcopy noencryption
Source: "brand_logo.bmp"; Flags: dontcopy noencryption

; Seluruh berkas keluaran dari 'flutter build windows --release'
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

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
indonesian.Step1=1. Lisensi
indonesian.Step2=2. Lokasi
indonesian.Step3=3. Instalasi
indonesian.Step4=4. Selesai
indonesian.TagLicense=LANGKAH 01 / 04  •  PERJANJIAN LISENSI
indonesian.TitleLicense=Syarat & Ketentuan Penggunaan
indonesian.SubLicense=Silakan baca dokumen di bawah, lalu pilih "Saya menyetujui" untuk melanjutkan.
indonesian.TagDir=LANGKAH 02 / 04  •  KONFIGURASI INSTALASI
indonesian.TitleDir=Pilih Lokasi & Opsi Pintasan
indonesian.SubDir=Tentukan direktori penyimpanan aplikasi serta pintasan akses cepat Cineva.
indonesian.TagReady=LANGKAH 02 / 04  •  KONFIRMASI AKHIR
indonesian.TitleReady=Siap Memasang Cineva Stream
indonesian.SubReady=Seluruh konfigurasi telah siap. Klik Pasang untuk memulai ekstraksi berkas.
indonesian.TagInstalling=LANGKAH 03 / 04  •  MEMASANG CINEVA
indonesian.TitleInstalling=Menyiapkan Pengalaman Sinematik Anda...
indonesian.SubInstalling1=Streaming Film & Serial TV favorit dengan antarmuka Obsidian modern.
indonesian.SubInstalling2=Dukungan penuh sinkronisasi instan antar HP, Tablet, PC & Android TV.
indonesian.SubInstalling3=Pemutar video berkinerja tinggi dengan kustomisasi subtitle real-time.
indonesian.TagFinished=LANGKAH 04 / 04  •  INSTALASI SELESAI
indonesian.TitleFinished=Cineva Siap Digunakan!
indonesian.SubFinished=Pemasangan berhasil diselesaikan. Selamat menikmati tayangan favorit Anda.
indonesian.FooterTagline=CINEVA STREAM  •  PENGALAMAN BIOSKOP MODERN

indonesian.UninstallTitle=Pelepasan Cineva
indonesian.UninstallPrompt=Apakah Anda yakin ingin menghapus Cineva dan semua komponennya dari komputer Anda?
indonesian.KeepMyData=Simpan data saya (Watchlist, Riwayat Tontonan & Pengaturan)
indonesian.BtnYes=&Ya, Hapus
indonesian.BtnNo=&Batal

english.Step1=1. License
english.Step2=2. Location
english.Step3=3. Install
english.Step4=4. Finish
english.TagLicense=STEP 01 / 04  •  LICENSE AGREEMENT
english.TitleLicense=Software Terms & Conditions
english.SubLicense=Please read the agreement below and select "I accept the agreement" to continue.
english.TagDir=STEP 02 / 04  •  INSTALLATION SETUP
english.TitleDir=Choose Location & Shortcuts
english.SubDir=Select the destination folder and desktop shortcut preferences for Cineva.
english.TagReady=STEP 02 / 04  •  READY TO INSTALL
english.TitleReady=Ready to Install Cineva Stream
english.SubReady=All settings are configured. Click Install to begin extracting application files.
english.TagInstalling=STEP 03 / 04  •  INSTALLING CINEVA
english.TitleInstalling=Setting Up Your Cinema Experience...
english.SubInstalling1=Stream movies & TV series in a sleek Obsidian & Cinema Amber interface.
english.SubInstalling2=Seamless multi-device sync across Smartphone, Tablet, PC & Android TV.
english.SubInstalling3=High-performance media engine with real-time subtitle customization.
english.TagFinished=STEP 04 / 04  •  SETUP COMPLETE
english.TitleFinished=Cineva is Ready to Stream!
english.SubFinished=Installation completed successfully. Launch Cineva and start watching.
english.FooterTagline=CINEVA STREAM  •  MODERN CINEMA EXPERIENCE

english.UninstallTitle=Cineva Uninstall
english.UninstallPrompt=Are you sure you want to completely remove Cineva and all of its components from your computer?
english.KeepMyData=Keep my data (Watchlist, Watch History & Settings)
english.BtnYes=&Yes, Remove
english.BtnNo=&Cancel

[Code]
const
  MARQUEE_VIEW_W = 700;
  MARQUEE_VIEW_H = 160;
  MARQUEE_TILE_W = 896;
  MARQUEE_TIMER_ID = 777;
  MARQUEE_INTERVAL_MS = 33;

  // Palet Warna BGR (TColor: $BBGGRR)
  CLR_OBSIDIAN_BG    = $0A0707; // #07070A
  CLR_CHARCOAL_BODY  = $140E0E; // #0E0E14
  CLR_CARD_SURFACE   = $201616; // #161620
  CLR_PILL_INACTIVE  = $261C1C; // #1C1C26
  CLR_PILL_DONE      = $12283D; // #3D2812 (Dark Amber Tint)
  CLR_AMBER_PRIMARY  = $0095FF; // #FF9500 (Cinema Amber)
  CLR_AMBER_LIGHT    = $47B3FF; // #FFB347 (Warm Gold)
  CLR_TEXT_WHITE     = $FAF8F8; // #F8F8FA
  CLR_TEXT_SLATE     = $DCE4E4; // #E4E4DC
  CLR_TEXT_MUTED     = $9E9494; // #94949E

function SetTimer(hWnd: HWND; nIDEvent, uElapse: UINT; lpTimerFunc: LongWord): UINT;
  external 'SetTimer@user32.dll stdcall';
function KillTimer(hWnd: HWND; uIDEvent: UINT): BOOL;
  external 'KillTimer@user32.dll stdcall';
function GetDC(hWnd: HWND): THandle;
  external 'GetDC@user32.dll stdcall';
function ReleaseDC(hWnd: HWND; hDC: THandle): Integer;
  external 'ReleaseDC@user32.dll stdcall';
function BitBlt(DestDC: THandle; X, Y, Width, Height: Integer; SrcDC: THandle; XSrc, YSrc: Integer; Rop: DWORD): BOOL;
  external 'BitBlt@gdi32.dll stdcall';
function StretchBlt(DestDC: THandle; X, Y, Width, Height: Integer; SrcDC: THandle; XSrc, YSrc, SrcWidth, SrcHeight: Integer; Rop: DWORD): BOOL;
  external 'StretchBlt@gdi32.dll stdcall';
function SetStretchBltMode(DC: THandle; StretchMode: Integer): Integer;
  external 'SetStretchBltMode@gdi32.dll stdcall';

var
  KeepDataChecked: Boolean;

  // Komponen Header & Animasi Poster Film
  HeaderPanel: TPanel;
  TopBrandBar: TPanel;
  BrandLogoImg: TBitmapImage;
  BrandTitleLbl: TNewStaticText;
  BrandVerLbl: TNewStaticText;
  StepPanels: array[1..4] of TPanel;
  StepLabels: array[1..4] of TNewStaticText;

  MarqueePanel: TPanel;
  MarqueeImg: TBitmapImage;
  StripBmp: TBitmap;
  BufferBmp: TBitmap;
  MarqueeOffsetX: Integer;
  MarqueeTickCount: Integer;

  CurrentTagText: String;
  CurrentTitleText: String;
  CurrentSubText: String;
  CurrentWizardPageID: Integer;

procedure RenderMarqueeFrame(SyncToImageControl: Boolean);
var
  SubTextToDraw: String;
  CycleIdx: Integer;
  DestDC: THandle;
begin
  if (StripBmp = nil) or (BufferBmp = nil) or (MarqueePanel = nil) then
    Exit;

  // 1. Salin potongan poster film sebesar 700x160 dari StripBmp ke BufferBmp di RAM (SRCCOPY = $00CC0020)
  BitBlt(
    BufferBmp.Canvas.Handle,
    0,
    0,
    MARQUEE_VIEW_W,
    MARQUEE_VIEW_H,
    StripBmp.Canvas.Handle,
    MarqueeOffsetX,
    0,
    $00CC0020
  );

  // Saat proses instalasi berjalan, rotasikan teks highlight fitur setiap ~4 detik
  SubTextToDraw := CurrentSubText;
  if CurrentWizardPageID = wpInstalling then
  begin
    CycleIdx := (MarqueeTickCount div 120) mod 3;
    if CycleIdx = 0 then
      SubTextToDraw := CustomMessage('SubInstalling1')
    else if CycleIdx = 1 then
      SubTextToDraw := CustomMessage('SubInstalling2')
    else
      SubTextToDraw := CustomMessage('SubInstalling3');
  end;

  BufferBmp.Canvas.Brush.Style := bsClear;
  BufferBmp.Canvas.Font.Name := 'Segoe UI';

  // 2. Label Kategori / Step Tag (Cinema Amber Bold)
  BufferBmp.Canvas.Font.Size := 8;
  BufferBmp.Canvas.Font.Style := [fsBold];
  BufferBmp.Canvas.Font.Color := $000000;
  BufferBmp.Canvas.TextOut(27, 65, CurrentTagText);
  BufferBmp.Canvas.Font.Color := CLR_AMBER_PRIMARY;
  BufferBmp.Canvas.TextOut(26, 64, CurrentTagText);

  // 3. Judul Utama Halaman (Putih Tebal dengan Drop Shadow Halus)
  BufferBmp.Canvas.Font.Size := 16;
  BufferBmp.Canvas.Font.Style := [fsBold];
  BufferBmp.Canvas.Font.Color := $000000;
  BufferBmp.Canvas.TextOut(27, 85, CurrentTitleText);
  BufferBmp.Canvas.Font.Color := CLR_TEXT_WHITE;
  BufferBmp.Canvas.TextOut(26, 84, CurrentTitleText);

  // 4. Subjudul Deskripsi Halaman (Slate Terang)
  BufferBmp.Canvas.Font.Size := 9;
  BufferBmp.Canvas.Font.Style := [];
  BufferBmp.Canvas.Font.Color := $000000;
  BufferBmp.Canvas.TextOut(27, 119, SubTextToDraw);
  BufferBmp.Canvas.Font.Color := CLR_TEXT_SLATE;
  BufferBmp.Canvas.TextOut(26, 118, SubTextToDraw);

  // 5. Hanya assign ke TBitmapImage saat perpindahan halaman (untuk fallback WM_PAINT),
  //    sedangkan saat animasi timer gunakan direct GDI StretchBlt ke HWND MarqueePanel
  //    agar TIDAK memicu WM_ERASEBKGND yang menyebabkan efek berkedip (flicker)!
  if SyncToImageControl and (MarqueeImg <> nil) then
    MarqueeImg.Bitmap.Assign(BufferBmp);

  if MarqueePanel.Handle <> 0 then
  begin
    DestDC := GetDC(MarqueePanel.Handle);
    if DestDC <> 0 then
    begin
      SetStretchBltMode(DestDC, 3); // COLORONCOLOR
      StretchBlt(
        DestDC,
        0,
        0,
        MarqueePanel.Width,
        MarqueePanel.Height,
        BufferBmp.Canvas.Handle,
        0,
        0,
        MARQUEE_VIEW_W,
        MARQUEE_VIEW_H,
        $00CC0020
      );
      ReleaseDC(MarqueePanel.Handle, DestDC);
    end;
  end;
end;

procedure OnMarqueeTimer(hWnd: HWND; uMsg: UINT; idEvent: UINT; dwTime: DWORD);
begin
  MarqueeOffsetX := (MarqueeOffsetX + 1) mod MARQUEE_TILE_W;
  MarqueeTickCount := MarqueeTickCount + 1;
  RenderMarqueeFrame(False);
end;

procedure LayoutFinishedPage();
begin
  WizardForm.FinishedHeadingLabel.Left := ScaleX(28);
  WizardForm.FinishedHeadingLabel.Top := ScaleY(16);
  WizardForm.FinishedHeadingLabel.Width := WizardForm.OuterNotebook.Width - ScaleX(56);
  WizardForm.FinishedHeadingLabel.Font.Size := 14;
  WizardForm.FinishedHeadingLabel.StyleElements := WizardForm.FinishedHeadingLabel.StyleElements - [seFont];
  WizardForm.FinishedHeadingLabel.Font.Color := CLR_AMBER_LIGHT;
  WizardForm.FinishedHeadingLabel.AdjustHeight();

  WizardForm.FinishedLabel.Left := ScaleX(28);
  WizardForm.FinishedLabel.Top := WizardForm.FinishedHeadingLabel.Top + WizardForm.FinishedHeadingLabel.Height + ScaleY(12);
  WizardForm.FinishedLabel.Width := WizardForm.OuterNotebook.Width - ScaleX(56);
  WizardForm.FinishedLabel.AdjustHeight();

  WizardForm.RunList.Left := ScaleX(28);
  WizardForm.RunList.Top := WizardForm.FinishedLabel.Top + WizardForm.FinishedLabel.Height + ScaleY(18);
  WizardForm.RunList.Width := WizardForm.OuterNotebook.Width - ScaleX(56);
  WizardForm.RunList.Height := ScaleY(72);
end;

procedure UpdateStepIndicators(ActiveStep: Integer);
var
  I: Integer;
  BaseCaption: String;
begin
  for I := 1 to 4 do
  begin
    if StepPanels[I] = nil then
      Continue;

    BaseCaption := CustomMessage('Step' + IntToStr(I));
    StepPanels[I].StyleElements := StepPanels[I].StyleElements - [seClient, seBorder];
    StepLabels[I].StyleElements := StepLabels[I].StyleElements - [seFont];

    if I = ActiveStep then
    begin
      StepPanels[I].Color := CLR_AMBER_PRIMARY;
      StepLabels[I].Font.Color := CLR_OBSIDIAN_BG;
      StepLabels[I].Font.Style := [fsBold];
      StepLabels[I].Caption := BaseCaption;
    end
    else if I < ActiveStep then
    begin
      StepPanels[I].Color := CLR_PILL_DONE;
      StepLabels[I].Font.Color := CLR_AMBER_LIGHT;
      StepLabels[I].Font.Style := [fsBold];
      StepLabels[I].Caption := '✓ ' + BaseCaption;
    end
    else
    begin
      StepPanels[I].Color := CLR_PILL_INACTIVE;
      StepLabels[I].Font.Color := CLR_TEXT_MUTED;
      StepLabels[I].Font.Style := [];
      StepLabels[I].Caption := BaseCaption;
    end;
  end;
end;

procedure InitializeWizard();
var
  HeaderH, TopBarH, MarqueeH: Integer;
  OrigInnerH, OldOuterBottom, NewOuterBottom, ExtraWindowH: Integer;
  PillW, PillH, PillGap, RightEdge, I: Integer;
  FooterBrandLbl: TNewStaticText;
begin
  // Ekstrak aset visual ke direktori sementara {tmp}
  ExtractTemporaryFile('marquee_strip.bmp');
  ExtractTemporaryFile('brand_logo.bmp');

  TopBarH := ScaleY(42);
  MarqueeH := ScaleY(138);
  HeaderH := TopBarH + MarqueeH;

  // Simpan tinggi asli InnerNotebook agar seluruh kontrol di dalamnya
  // (LicenseMemo, RadioButton Setuju, DirEdit, TasksList, ProgressBar)
  // TIDAK PERNAH mengecil atau tergeser keluar layar oleh VCL Anchors!
  OrigInnerH := WizardForm.InnerNotebook.Height;
  OldOuterBottom := WizardForm.OuterNotebook.Top + WizardForm.OuterNotebook.Height;

  // Lepaskan sementara akBottom pada OuterNotebook & InnerNotebook sebelum mengubah ukuran
  WizardForm.OuterNotebook.Anchors := [akLeft, akTop, akRight];
  WizardForm.InnerNotebook.Anchors := [akLeft, akTop, akRight];

  // Sembunyikan header bawaan Inno Setup
  WizardForm.MainPanel.Visible := False;
  WizardForm.Bevel.Visible := False;
  WizardForm.WizardBitmapImage.Visible := False;
  WizardForm.WizardBitmapImage2.Visible := False;

  // Posisikan InnerNotebook di bagian atas OuterNotebook dengan tinggi asli 100% utuh
  WizardForm.InnerNotebook.Top := ScaleY(10);
  WizardForm.InnerNotebook.Height := OrigInnerH;

  // Posisikan OuterNotebook tepat di bawah HeaderPanel
  WizardForm.OuterNotebook.Top := HeaderH;
  WizardForm.OuterNotebook.Height := WizardForm.InnerNotebook.Top + OrigInnerH + ScaleY(10);

  // Perbesar tinggi jendela sebesar selisih batas bawah OuterNotebook baru vs lama
  // (Tombol Next, Back, dan Cancel otomatis turun karena memiliki akBottom)
  NewOuterBottom := WizardForm.OuterNotebook.Top + WizardForm.OuterNotebook.Height;
  ExtraWindowH := NewOuterBottom - OldOuterBottom;
  if ExtraWindowH > 0 then
    WizardForm.ClientHeight := WizardForm.ClientHeight + ExtraWindowH;

  // Kembalikan Anchors seperti semula setelah posisi final terkunci
  WizardForm.InnerNotebook.Anchors := [akLeft, akTop, akRight, akBottom];
  WizardForm.OuterNotebook.Anchors := [akLeft, akTop, akRight, akBottom];

  // Warna latar belakang Obsidian & penegasan tampilan halaman Lisensi
  WizardForm.Color := CLR_CHARCOAL_BODY;
  WizardForm.LicenseMemo.Color := CLR_CARD_SURFACE;
  WizardForm.LicenseAcceptedRadio.Font.Style := [fsBold];

  // ── 1. Panel Induk Header (TopBrandBar + Poster Wall Marquee) ──
  HeaderPanel := TPanel.Create(WizardForm);
  HeaderPanel.Parent := WizardForm;
  HeaderPanel.Left := 0;
  HeaderPanel.Top := 0;
  HeaderPanel.Width := WizardForm.ClientWidth;
  HeaderPanel.Height := HeaderH;
  HeaderPanel.Anchors := [akLeft, akTop, akRight];
  HeaderPanel.BevelOuter := bvNone;
  HeaderPanel.ParentBackground := False;
  HeaderPanel.StyleElements := HeaderPanel.StyleElements - [seClient, seBorder];
  HeaderPanel.Color := CLR_OBSIDIAN_BG;

  // ── 2. Top Brand & 4-Step Progress Bar ──
  TopBrandBar := TPanel.Create(HeaderPanel);
  TopBrandBar.Parent := HeaderPanel;
  TopBrandBar.Left := 0;
  TopBrandBar.Top := 0;
  TopBrandBar.Width := HeaderPanel.Width;
  TopBrandBar.Height := TopBarH;
  TopBrandBar.Anchors := [akLeft, akTop, akRight];
  TopBrandBar.BevelOuter := bvNone;
  TopBrandBar.ParentBackground := False;
  TopBrandBar.StyleElements := TopBrandBar.StyleElements - [seClient, seBorder];
  TopBrandBar.Color := CLR_OBSIDIAN_BG;

  BrandLogoImg := TBitmapImage.Create(TopBrandBar);
  BrandLogoImg.Parent := TopBrandBar;
  BrandLogoImg.Left := ScaleX(20);
  BrandLogoImg.Top := (TopBarH - ScaleY(24)) div 2;
  BrandLogoImg.Width := ScaleX(24);
  BrandLogoImg.Height := ScaleY(24);
  BrandLogoImg.Stretch := True;
  BrandLogoImg.Bitmap.LoadFromFile(ExpandConstant('{tmp}\brand_logo.bmp'));

  BrandTitleLbl := TNewStaticText.Create(TopBrandBar);
  BrandTitleLbl.Parent := TopBrandBar;
  BrandTitleLbl.Left := BrandLogoImg.Left + BrandLogoImg.Width + ScaleX(9);
  BrandTitleLbl.Top := (TopBarH - ScaleY(19)) div 2;
  BrandTitleLbl.Caption := 'CINEVA';
  BrandTitleLbl.Font.Name := 'Segoe UI';
  BrandTitleLbl.Font.Size := 11;
  BrandTitleLbl.Font.Style := [fsBold];
  BrandTitleLbl.StyleElements := BrandTitleLbl.StyleElements - [seFont];
  BrandTitleLbl.Font.Color := CLR_TEXT_WHITE;

  BrandVerLbl := TNewStaticText.Create(TopBrandBar);
  BrandVerLbl.Parent := TopBrandBar;
  BrandVerLbl.Left := BrandTitleLbl.Left + BrandTitleLbl.Width + ScaleX(8);
  BrandVerLbl.Top := (TopBarH - ScaleY(15)) div 2 + ScaleY(1);
  BrandVerLbl.Caption := 'v{#MyAppVersion}';
  BrandVerLbl.Font.Name := 'Segoe UI';
  BrandVerLbl.Font.Size := 8;
  BrandVerLbl.Font.Style := [fsBold];
  BrandVerLbl.StyleElements := BrandVerLbl.StyleElements - [seFont];
  BrandVerLbl.Font.Color := CLR_AMBER_PRIMARY;

  // Buat 4 Indikator Langkah (Step Pills) di sisi kanan TopBrandBar
  PillW := ScaleX(82);
  PillH := ScaleY(24);
  PillGap := ScaleX(6);
  RightEdge := TopBrandBar.Width - ScaleX(20);

  for I := 4 downto 1 do
  begin
    StepPanels[I] := TPanel.Create(TopBrandBar);
    StepPanels[I].Parent := TopBrandBar;
    StepPanels[I].Width := PillW;
    StepPanels[I].Height := PillH;
    StepPanels[I].Left := RightEdge - ((4 - I + 1) * PillW) - ((4 - I) * PillGap);
    StepPanels[I].Top := (TopBarH - PillH) div 2;
    StepPanels[I].Anchors := [akTop, akRight];
    StepPanels[I].BevelOuter := bvNone;
    StepPanels[I].ParentBackground := False;
    StepPanels[I].StyleElements := StepPanels[I].StyleElements - [seClient, seBorder];
    StepPanels[I].Color := CLR_PILL_INACTIVE;

    StepLabels[I] := TNewStaticText.Create(StepPanels[I]);
    StepLabels[I].Parent := StepPanels[I];
    StepLabels[I].AutoSize := False;
    StepLabels[I].Left := 0;
    StepLabels[I].Top := ScaleY(4);
    StepLabels[I].Width := PillW;
    StepLabels[I].Height := PillH - ScaleY(4);
    StepLabels[I].Alignment := taCenter;
    StepLabels[I].Font.Name := 'Segoe UI';
    StepLabels[I].Font.Size := 8;
    StepLabels[I].StyleElements := StepLabels[I].StyleElements - [seFont];
    StepLabels[I].Caption := CustomMessage('Step' + IntToStr(I));
  end;

  // ── 3. Animated Cinema Poster Wall Marquee (Zero-Flicker Dedicated HWND Panel) ──
  StripBmp := TBitmap.Create();
  StripBmp.LoadFromFile(ExpandConstant('{tmp}\marquee_strip.bmp'));

  BufferBmp := TBitmap.Create();
  BufferBmp.Width := MARQUEE_VIEW_W;
  BufferBmp.Height := MARQUEE_VIEW_H;

  MarqueePanel := TPanel.Create(HeaderPanel);
  MarqueePanel.Parent := HeaderPanel;
  MarqueePanel.Left := 0;
  MarqueePanel.Top := TopBarH;
  MarqueePanel.Width := HeaderPanel.Width;
  MarqueePanel.Height := MarqueeH;
  MarqueePanel.Anchors := [akLeft, akTop, akRight];
  MarqueePanel.BevelOuter := bvNone;
  MarqueePanel.ParentBackground := False;
  MarqueePanel.StyleElements := MarqueePanel.StyleElements - [seClient, seBorder];
  MarqueePanel.Color := CLR_OBSIDIAN_BG;

  MarqueeImg := TBitmapImage.Create(MarqueePanel);
  MarqueeImg.Parent := MarqueePanel;
  MarqueeImg.Left := 0;
  MarqueeImg.Top := 0;
  MarqueeImg.Width := MarqueePanel.Width;
  MarqueeImg.Height := MarqueePanel.Height;
  MarqueeImg.Anchors := [akLeft, akTop, akRight, akBottom];
  MarqueeImg.Stretch := True;

  // ── 4. Tata Ulang Halaman Selesai (FinishedPage) Agar Selaras di Bawah Marquee ──
  LayoutFinishedPage();

  // ── 5. Label Branding Halus di Pojok Kiri Bawah Footer ──
  FooterBrandLbl := TNewStaticText.Create(WizardForm);
  FooterBrandLbl.Parent := WizardForm;
  FooterBrandLbl.Left := ScaleX(24);
  FooterBrandLbl.Top := WizardForm.CancelButton.Top + (WizardForm.CancelButton.Height - ScaleY(14)) div 2;
  FooterBrandLbl.Anchors := [akLeft, akBottom];
  FooterBrandLbl.Caption := CustomMessage('FooterTagline');
  FooterBrandLbl.Font.Name := 'Segoe UI';
  FooterBrandLbl.Font.Size := 8;
  FooterBrandLbl.Font.Style := [fsBold];
  FooterBrandLbl.StyleElements := FooterBrandLbl.StyleElements - [seFont];
  FooterBrandLbl.Font.Color := CLR_TEXT_MUTED;

  // Mulai animasi Cinema Poster Wall (~30 FPS bebas kedip)
  MarqueeOffsetX := 0;
  MarqueeTickCount := 0;
  CurrentWizardPageID := wpLicense;
  CurrentTagText := CustomMessage('TagLicense');
  CurrentTitleText := CustomMessage('TitleLicense');
  CurrentSubText := CustomMessage('SubLicense');
  UpdateStepIndicators(1);
  RenderMarqueeFrame(True);

  SetTimer(WizardForm.Handle, MARQUEE_TIMER_ID, MARQUEE_INTERVAL_MS, CreateCallback(@OnMarqueeTimer));
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  CurrentWizardPageID := CurPageID;

  case CurPageID of
    wpWelcome, wpLicense:
      begin
        CurrentTagText := CustomMessage('TagLicense');
        CurrentTitleText := CustomMessage('TitleLicense');
        CurrentSubText := CustomMessage('SubLicense');
        UpdateStepIndicators(1);
      end;
    wpSelectDir, wpSelectComponents, wpSelectProgramGroup, wpSelectTasks:
      begin
        CurrentTagText := CustomMessage('TagDir');
        CurrentTitleText := CustomMessage('TitleDir');
        CurrentSubText := CustomMessage('SubDir');
        UpdateStepIndicators(2);
      end;
    wpReady:
      begin
        CurrentTagText := CustomMessage('TagReady');
        CurrentTitleText := CustomMessage('TitleReady');
        CurrentSubText := CustomMessage('SubReady');
        UpdateStepIndicators(2);
      end;
    wpPreparing, wpInstalling:
      begin
        CurrentTagText := CustomMessage('TagInstalling');
        CurrentTitleText := CustomMessage('TitleInstalling');
        CurrentSubText := CustomMessage('SubInstalling1');
        UpdateStepIndicators(3);
      end;
    wpInfoAfter, wpFinished:
      begin
        CurrentTagText := CustomMessage('TagFinished');
        CurrentTitleText := CustomMessage('TitleFinished');
        CurrentSubText := CustomMessage('SubFinished');
        UpdateStepIndicators(4);
        LayoutFinishedPage();
      end;
  end;

  RenderMarqueeFrame(True);
end;

procedure DeinitializeSetup();
begin
  if (WizardForm <> nil) and (WizardForm.Handle <> 0) then
    KillTimer(WizardForm.Handle, MARQUEE_TIMER_ID);
end;

function InitializeUninstall(): Boolean;
var
  CustomForm: TSetupForm;
  HeaderBar: TPanel;
  AccentLine: TPanel;
  HeaderTitleLbl: TNewStaticText;
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

  CustomForm := CreateCustomForm(ScaleX(460), ScaleY(215), False, True);
  try
    CustomForm.Caption := CustomMessage('UninstallTitle');
    CustomForm.Position := poScreenCenter;
    CustomForm.Color := CLR_CHARCOAL_BODY;

    HeaderBar := TPanel.Create(CustomForm);
    HeaderBar.Parent := CustomForm;
    HeaderBar.Left := 0;
    HeaderBar.Top := 0;
    HeaderBar.Width := CustomForm.ClientWidth;
    HeaderBar.Height := ScaleY(42);
    HeaderBar.BevelOuter := bvNone;
    HeaderBar.ParentBackground := False;
    HeaderBar.StyleElements := HeaderBar.StyleElements - [seClient, seBorder];
    HeaderBar.Color := CLR_OBSIDIAN_BG;

    HeaderTitleLbl := TNewStaticText.Create(HeaderBar);
    HeaderTitleLbl.Parent := HeaderBar;
    HeaderTitleLbl.Left := ScaleX(24);
    HeaderTitleLbl.Top := ScaleY(12);
    HeaderTitleLbl.Caption := 'CINEVA  •  ' + UpperCase(CustomMessage('UninstallTitle'));
    HeaderTitleLbl.Font.Name := 'Segoe UI';
    HeaderTitleLbl.Font.Size := 9;
    HeaderTitleLbl.Font.Style := [fsBold];
    HeaderTitleLbl.StyleElements := HeaderTitleLbl.StyleElements - [seFont];
    HeaderTitleLbl.Font.Color := CLR_AMBER_PRIMARY;

    AccentLine := TPanel.Create(CustomForm);
    AccentLine.Parent := CustomForm;
    AccentLine.Left := 0;
    AccentLine.Top := HeaderBar.Height;
    AccentLine.Width := CustomForm.ClientWidth;
    AccentLine.Height := ScaleY(2);
    AccentLine.BevelOuter := bvNone;
    AccentLine.ParentBackground := False;
    AccentLine.StyleElements := AccentLine.StyleElements - [seClient, seBorder];
    AccentLine.Color := CLR_AMBER_PRIMARY;

    PromptLabel := TNewStaticText.Create(CustomForm);
    PromptLabel.Parent := CustomForm;
    PromptLabel.Left := ScaleX(24);
    PromptLabel.Top := ScaleY(58);
    PromptLabel.Width := CustomForm.ClientWidth - ScaleX(48);
    PromptLabel.Height := ScaleY(48);
    PromptLabel.WordWrap := True;
    PromptLabel.Caption := CustomMessage('UninstallPrompt');
    PromptLabel.Font.Name := 'Segoe UI';
    PromptLabel.Font.Size := 9;
    PromptLabel.StyleElements := PromptLabel.StyleElements - [seFont];
    PromptLabel.Font.Color := CLR_TEXT_WHITE;

    KeepDataCheckBox := TNewCheckBox.Create(CustomForm);
    KeepDataCheckBox.Parent := CustomForm;
    KeepDataCheckBox.Left := ScaleX(24);
    KeepDataCheckBox.Top := ScaleY(112);
    KeepDataCheckBox.Width := CustomForm.ClientWidth - ScaleX(48);
    KeepDataCheckBox.Height := ScaleY(24);
    KeepDataCheckBox.Caption := CustomMessage('KeepMyData');
    KeepDataCheckBox.Checked := False;

    YesButton := TNewButton.Create(CustomForm);
    YesButton.Parent := CustomForm;
    YesButton.Left := CustomForm.ClientWidth - ScaleX(206);
    YesButton.Top := CustomForm.ClientHeight - ScaleY(46);
    YesButton.Width := ScaleX(86);
    YesButton.Height := ScaleY(28);
    YesButton.Caption := CustomMessage('BtnYes');
    YesButton.ModalResult := mrOk;
    YesButton.Default := True;

    NoButton := TNewButton.Create(CustomForm);
    NoButton.Parent := CustomForm;
    NoButton.Left := CustomForm.ClientWidth - ScaleX(110);
    NoButton.Top := CustomForm.ClientHeight - ScaleY(46);
    NoButton.Width := ScaleX(86);
    NoButton.Height := ScaleY(28);
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
