; Planles Windows installer (Inno Setup)
; Build with:
;   ISCC /DMyAppVersion=0.1.0 /DSourceDir="build\windows\x64\runner\Release" /DOutputDir="dist" tool\windows_installer.iss

#ifndef MyAppVersion
#define MyAppVersion "0.0.0"
#endif

#ifndef MyAppName
#define MyAppName "Planles"
#endif

#ifndef MyAppExeName
#define MyAppExeName "planles_custom.exe"
#endif

#ifndef SourceDir
#define SourceDir "build\windows\x64\runner\Release"
#endif

#ifndef OutputDir
#define OutputDir "dist"
#endif

#ifndef OutputBaseFilename
#define OutputBaseFilename "Planles-" + MyAppVersion + "-windows-x64-setup"
#endif

[Setup]
AppId={{B8D8E8D4-7A7D-4D5F-9D9D-8F7A1C2B3E4F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=Planles
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseFilename}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Custom URL scheme so Mollie payment redirects (planles://...) can open the app.
Root: HKCU; Subkey: "Software\Classes\planles"; ValueType: string; ValueName: ""; ValueData: "URL:Planles Protocol"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\planles"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\planles\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\planles\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
