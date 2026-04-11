#define MyAppName "IcyEasySend"
#define MyAppVersion "1.2.0"
#define MyAppPublisher "IcyHope"
#define MyAppURL "https://binglengdexiwang.top"
#define MyAppExeName "IcyEasySend.exe"

[Setup]
AppId={{CFFAE83F-4172-4BB1-8C42-1D1D35A5EBD0}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
UninstallDisplayIcon={app}\app_icon.ico
PrivilegesRequired=admin
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
OutputBaseFilename={#MyAppName}_setup_{#MyAppVersion}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes

[VersionInfo]
CompanyVersion={#MyAppVersion}
CompanyVersionNumbers=1,0,9,0
CompanyName={#MyAppPublisher}
FileDescription={#MyAppName} Setup
FileVersion={#MyAppVersion}
FileVersionNumbers=1,0,9,0
ProductName={#MyAppName}
ProductVersion={#MyAppVersion}
ProductVersionNumbers=1,0,9,0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
; checkedonce: 首次安装默认勾选，升级安装保持上次选择
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\windows\runner\resources\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\app_icon.ico"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent