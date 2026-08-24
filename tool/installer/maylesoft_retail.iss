; MayleSoft retail — Windows web installer (Inno Setup 6/7)

#ifndef MyAppVersion
  #define MyAppVersion "0.1.0"
#endif
#ifndef MyAppBuild
  #define MyAppBuild "1"
#endif

#define MyAppName "MayleSoft retail"
#define MyAppPublisher "MayleSoft"
#define MyAppURL "https://retail.maylesoft.com"
#define MyAppExeName "retail.exe"
#define SourceDir "..\..\build\windows\x64\runner\Release"
#define IconPath "..\..\windows\runner\resources\app_icon.ico"

[Setup]
AppId={{A7C4E2B1-9F3D-4A6E-8C1B-2D5E7F9A0B3C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=MayleSoftRetail-Setup-{#MyAppVersion}
SetupIconFile={#IconPath}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
; Code-signing: the PowerShell build script signs retail.exe and the Setup
; output with SignTool when MAYLESOFT_SIGN_PFX is set (see tool\CODE_SIGNING.md).
; Inno SignTool= is intentionally unused so unsigned local builds keep working.

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Messages]
WelcomeLabel2=This will install [name/ver] on your computer.%n%nMayleSoft retail is an offline POS and inventory manager for small stores.
