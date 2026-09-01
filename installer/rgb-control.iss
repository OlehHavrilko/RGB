; Inno Setup — инсталлятор RGB Control (Windows x64).
; Сборка: iscc /DMyAppVersion=1.0.0 installer\rgb-control.iss
; Перед этим должен быть выполнен `flutter build windows --release` в app/.

#define MyAppName "RGB Control"
#define MyAppPublisher "Oleh Havrilko"
#define MyAppExeName "rgb_controller.exe"
#define MyAppUrl "https://github.com/OlehHavrilko/RGB"

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\app\build\windows\x64\runner\Release"
#endif

[Setup]
AppId={{A3F5C1E2-9B47-4D8A-B6E0-1C2D3E4F5A6B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppUrl}
AppSupportURL={#MyAppUrl}
DefaultDirName={autopf}\RGB Control
DefaultGroupName=RGB Control
DisableProgramGroupPage=yes
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputDir=..\dist
OutputBaseFilename=RGB-Control-Setup-x64
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
Name: "{group}\RGB Control"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,RGB Control}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\RGB Control"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,RGB Control}"; Flags: nowait postinstall skipifsilent
