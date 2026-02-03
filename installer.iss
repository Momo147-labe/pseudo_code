#define AppName "Algorithme Univ Labé"
#define AppVersion "1.0.0"
#define AppPublisher "Fode Momo Soumah"
#define AppURL "https://github.com/Momo147-labe"
#define AppExeName "algorithme_univ_labe.exe"
#define AppId "9F7A6C2E-8B5D-4C7F-A2E1-123656789ABC"

[Setup]
; ✅ INFORMATIONS OBLIGATOIRES (éviter "Éditeur inconnu")
AppId={{{#AppId}}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
AppCopyright=Copyright © 2024 {#AppPublisher}
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName}
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}

; ✅ CONFIGURATION INSTALLATION
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
LicenseFile=
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=Output
OutputBaseFilename=Setup-{#AppName}-{#AppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; ✅ SÉCURITÉ WINDOWS
DisableProgramGroupPage=yes
DisableReadyPage=no
DisableFinishedPage=no
DisableWelcomePage=no
ShowLanguageDialog=no
UsePreviousAppDir=yes
UsePreviousGroup=yes
UpdateUninstallLogAppName=yes
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le bureau"; GroupDescription: "Raccourcis:"; Flags: unchecked
Name: "quicklaunchicon"; Description: "Créer un raccourci dans la barre de lancement rapide"; GroupDescription: "Raccourcis:"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
; ✅ APPLICATION FLUTTER
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; ✅ RUNTIME VISUAL C++ (éviter erreurs DLL)
Source: "C:\Windows\System32\vcruntime140.dll"; DestDir: "{app}"; Flags: external skipifsourcedoesntexist
Source: "C:\Windows\System32\msvcp140.dll"; DestDir: "{app}"; Flags: external skipifsourcedoesntexist
Source: "C:\Windows\System32\vcruntime140_1.dll"; DestDir: "{app}"; Flags: external skipifsourcedoesntexist

[Registry]
; ✅ ENREGISTREMENT APPLICATION
Root: HKCU; Subkey: "Software\{#AppPublisher}\{#AppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
Root: HKCU; Subkey: "Software\{#AppPublisher}\{#AppName}"; ValueType: string; ValueName: "Version"; ValueData: "{#AppVersion}"
Root: HKCU; Subkey: "Software\{#AppPublisher}\{#AppName}"; ValueType: dword; ValueName: "Installed"; ValueData: 1

; ============================
; ASSOCIATION FICHIERS .alg
; ============================

; extension .alg
Root: HKCU; Subkey: "Software\Classes\.alg"; ValueType: string; ValueData: "AlgFile"; Flags: uninsdeletevalue
; type de fichier
Root: HKCU; Subkey: "Software\Classes\AlgFile"; ValueType: string; ValueData: "Fichier Algorithme Univ Labé"; Flags: uninsdeletekey
; icône du fichier
Root: HKCU; Subkey: "Software\Classes\AlgFile\DefaultIcon"; ValueType: string; ValueData: "{app}\{#AppExeName},0"
; action ouvrir
Root: HKCU; Subkey: "Software\Classes\AlgFile\Shell\Open\Command"; ValueType: string; ValueData: """{app}\{#AppExeName}"" ""%1"""


; ============================
; ASSOCIATION FICHIERS .csi
; ============================

; extension .csi
Root: HKCU; Subkey: "Software\Classes\.csi"; ValueType: string; ValueData: "CsiFile"; Flags: uninsdeletevalue
; type de fichier
Root: HKCU; Subkey: "Software\Classes\CsiFile"; ValueType: string; ValueData: "Fichier Merise(csi) Univ Labé"; Flags: uninsdeletekey
; icône du fichier
Root: HKCU; Subkey: "Software\Classes\CsiFile\DefaultIcon"; ValueType: string; ValueData: "{app}\{#AppExeName},0"
; action ouvrir
Root: HKCU; Subkey: "Software\Classes\CsiFile\Shell\Open\Command"; ValueType: string; ValueData: """{app}\{#AppExeName}"" ""%1"""



[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
Name: "{group}\Désinstaller {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: quicklaunchicon

[Run]
; ✅ RÈGLES FIREWALL (autoriser réseau)
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""{#AppName} - Sortant"" dir=out action=allow program=""{app}\{#AppExeName}"" enable=yes"; Flags: runhidden; StatusMsg: "Configuration du pare-feu..."
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""{#AppName} - Entrant"" dir=in action=allow program=""{app}\{#AppExeName}"" enable=yes"; Flags: runhidden

; ✅ LANCEMENT POST-INSTALLATION
Filename: "{app}\{#AppExeName}"; Description: "Lancer {#AppName}"; Flags: nowait postinstall skipifsilent; WorkingDir: "{app}"

[UninstallRun]
; ✅ NETTOYAGE RÈGLES FIREWALL
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""{#AppName} - Sortant"""; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""{#AppName} - Entrant"""; Flags: runhidden

[UninstallDelete]
; ✅ NETTOYAGE DONNÉES UTILISATEUR (optionnel)
Type: filesandordirs; Name: "{userappdata}\{#AppPublisher}\{#AppName}"
Type: filesandordirs; Name: "{localappdata}\{#AppPublisher}\{#AppName}"

[Code]
// ✅ VÉRIFICATIONS PRÉ-INSTALLATION
function InitializeSetup(): Boolean;
begin
  Result := True;
  
  // Vérifier Windows 10/11
  if GetWindowsVersion < $0A000000 then begin
    MsgBox('Cette application nécessite Windows 10 ou supérieur.', mbError, MB_OK);
    Result := False;
  end;
end;

// ✅ CONFIGURATION POST-INSTALLATION
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then begin
    // Créer dossiers AppData si nécessaire
    CreateDir(ExpandConstant('{localappdata}\{#AppPublisher}'));
    CreateDir(ExpandConstant('{localappdata}\{#AppPublisher}\{#AppName}'));
  end;
end;

// ✅ NETTOYAGE PRÉ-DÉSINSTALLATION
function InitializeUninstall(): Boolean;
begin
  Result := True;
  if MsgBox('Voulez-vous également supprimer les données de l''application ?', mbConfirmation, MB_YESNO) = IDNO then
    Result := True;
end;