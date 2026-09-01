; Inno Setup — инсталлятор Chromify (Windows x64).
; Сборка: iscc /DMyAppVersion=1.0.0 installer\chromify.iss
; Перед этим должен быть выполнен `flutter build windows --release` в app/.

#define MyAppName "Chromify"
#define MyAppPublisher "Oleh Havrilko"
#define MyAppExeName "chromify.exe"
#define MyAppUrl "https://github.com/OlehHavrilko/RGB"

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\app\build\windows\x64\runner\Release"
#endif

[Setup]
AppId={{78D96576-3C6E-4631-BC9D-1B33479EF448}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppUrl}
AppSupportURL={#MyAppUrl}
DefaultDirName={autopf}\Chromify
DefaultGroupName=Chromify
DisableProgramGroupPage=yes
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputDir=..\dist
OutputBaseFilename=Chromify-Setup-x64
SetupIconFile=..\app\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Всё содержимое папки релиза Flutter (exe, flutter_windows.dll, плагины, data\).
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\Chromify"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,Chromify}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Chromify"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,Chromify}"; Flags: nowait postinstall skipifsilent
